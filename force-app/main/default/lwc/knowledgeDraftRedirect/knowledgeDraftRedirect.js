/**
 * ===============================================================================================
 * Component        : knowledgeDraftRedirect.js
 * Purpose          : Redirect the user from draft article to the published article.
 * Author           : Dylan Pluk
 * Created          : 2025-11-06
 * -----------------------------------------------------------------------------------------------
 * Change Log
 * 2025-11-06 | DP | Initial creation.
 * ===============================================================================================
 */

import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import resolve from '@salesforce/apex/KnowledgeRedirectController.resolve';
import {
  getEnclosingTabId,
  getFocusedTabInfo,
  getTabInfo,
  openTab,
  closeTab
} from 'lightning/platformWorkspaceApi';

export default class knowledgeDraftRedirect extends NavigationMixin(LightningElement) {
  @api recordId;

  @api
  get alsoCloseParentPrimary() { return this._alsoCloseParentPrimary; }
  set alsoCloseParentPrimary(v) { this._alsoCloseParentPrimary = (v === true); }
  _alsoCloseParentPrimary = false;

  lastProcessedId;
  message;

  // ---- utilities ----
  sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
  toast(title, message, variant = 'info', mode = 'dismissable') {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
  }

  /**
   * Obtain a Console tab id. Retries briefly to wait for Workspace API readiness.
   */
  async getTabIdWithRetry(maxTries = 10, delayMs = 200) {
    for (let i = 0; i < maxTries; i++) {
      try {
        const enclosing = await getEnclosingTabId();
        if (typeof enclosing === 'string' && enclosing) return enclosing;
      } catch {} // ignore
      try {
        const focused = await getFocusedTabInfo();
        const tabId = (focused && typeof focused.tabId === 'string') ? focused.tabId : null;
        if (tabId) return tabId;
      } catch {} // ignore
      await this.sleep(delayMs);
    }
    return null;
  }

  /**
   * Close a single tab (primary or subtab) with retry and a gentle focus hop.
   */
  async closeOneTab(tabId, label = 'closeTab') {
    const id = (typeof tabId === 'string') ? tabId : (tabId && tabId.tabId ? tabId.tabId : null);
    if (!id) return false;

    try {
      await closeTab(id);
      return true;
    } catch {
      try { await openTab({ url: '/lightning/page/home', focus: false }); } catch {}
      await this.sleep(300);
      try { await closeTab(id); return true; } catch {}
    }
    return false;
  }

  /**
   * Close a primary tab, attempting to close any subtabs first if available in tab info.
   */
  async closePrimaryWithSubtabs(primaryTabInfo) {
    if (!primaryTabInfo || !primaryTabInfo.tabId) return false;
    const subtabs = Array.isArray(primaryTabInfo.subtabs) ? primaryTabInfo.subtabs : [];
    for (const st of subtabs) { await this.closeOneTab(st.tabId, 'closeSubtab'); }
    return this.closeOneTab(primaryTabInfo.tabId, 'closePrimary');
  }

  /**
   * Close the current tab. If it's a subtab and alsoCloseParentPrimary = true,
   * optionally close its parent primary. If it's a primary, close subtabs first.
   */
  async closeCurrentTabSmart(currentTabId) {
    if (!currentTabId) return;
    const id = (typeof currentTabId === 'string') ? currentTabId : (currentTabId?.tabId || null);
    if (!id) { await this.closeOneTab(currentTabId, 'closeUnknown'); return; }

    let info = null;
    try { info = await getTabInfo({ tabId: id }); } catch {
      await this.closeOneTab(id, 'closeWithoutInfo');
      return;
    }

    const isSubtab = !!info.parentTabId;
    if (isSubtab) {
      await this.closeOneTab(id, 'closeSubtab');
      if (this._alsoCloseParentPrimary && info.parentTabId) {
        let parentInfo = null;
        try { parentInfo = await getTabInfo({ tabId: info.parentTabId }); } catch {}
        if (parentInfo) await this.closePrimaryWithSubtabs(parentInfo);
        else await this.closeOneTab(info.parentTabId, 'closeParentPrimary');
      }
      return;
    }

    await this.closePrimaryWithSubtabs(info);
  }

  /**
   * Main flow: resolve Online version; open it; close current tab. If none, warn + close later.
   * Runs once per recordId to handle Console's tab reuse.
   */
  async process() {
    if (!this.recordId || this.recordId === this.lastProcessedId) return;
    this.lastProcessedId = this.recordId;

    // Non-cacheable server decision
    let res;
    try { res = await resolve({ kavId: this.recordId }); }
    catch {
      this.message = 'Er is geen gepubliceerde versie van dit artikel.';
      this.toast('Concept versie', this.message, 'error', 'dismissable');
      setTimeout(() => { this.message = undefined; }, 3000);
      return;
    }
    if (!res || res.ok === false) {
      const msg = res?.errorMessage || 'Er is geen gepubliceerde versie van dit artikel.';
      this.message = msg;
      this.toast('Concept versie', msg, 'error', 'dismissable');
      setTimeout(() => { this.message = undefined; }, 3000);
      return;
    }
    if (res.isOnline) return;

    const currentTabId = await this.getTabIdWithRetry();

    if (res.onlineId) {
      // Open Online in a new primary tab, then close the current tab.
      let opened = false;
      try { await openTab({ recordId: res.onlineId, focus: true }); opened = true; }
      catch {
        this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: { recordId: res.onlineId, objectApiName: 'Knowledge__kav', actionName: 'view' }
        });
        opened = true;
      }
      if (opened && currentTabId) {
        setTimeout(() => this.closeCurrentTabSmart(currentTabId), 250);
      }
      return;
    }

    // No Online version: brief warning + auto-close after 3s
    this.message = 'Je hebt geen rechten om dit concept te bekijken. We sluiten dit artikel automatisch.';
    this.toast('Dit artikel is nog in concept', this.message, 'warning', 'dismissable');
    setTimeout(() => { this.message = undefined; }, 3000);

    if (currentTabId) {
      setTimeout(() => this.closeCurrentTabSmart(currentTabId), 3000);
    }
  }

  connectedCallback() { queueMicrotask(() => this.process()); }
  renderedCallback() { this.process(); }
}