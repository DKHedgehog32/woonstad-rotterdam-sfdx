/**
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * KNOWLEDGE DETAILS INTERNAL LIGHTNING WEB COMPONENT
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * @description    Lightning Web Component for displaying Salesforce Knowledge article details
 *                 Supports both record ID and URL name based article loading with topic navigation
 *                 Provides loading states, error handling, and responsive design
 * 
 * @author         Dennis van Musschenbroek
 * @created        2025-01-24
 * @version        2.0.0
 * @component      knowledgeDetailsInternal
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * FUNCTIONALITY OVERVIEW
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * This Lightning Web Component serves as a viewer for Salesforce Knowledge articles in internal
 * communities and Experience Cloud sites. It provides a clean, responsive interface for displaying
 * article content with proper loading states and error handling.
 * 
 * Key Features:
 * - Dynamic article loading by Record ID or URL Name
 * - Language-aware content retrieval
 * - Topic link generation with SEO-friendly URLs
 * - Loading state management with spinner
 * - Error state handling with user-friendly messages
 * - Page reference integration for URL parameter extraction
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * TECHNICAL IMPLEMENTATION
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * Following Salesforce Lightning Web Components best practices:
 * - Reactive properties with proper decorators (@api, @track, @wire)
 * - Async/await pattern for improved readability
 * - Error boundaries with graceful degradation
 * - Lifecycle hook optimization (connectedCallback)
 * - URL generation utility for topic navigation
 * - Memory leak prevention with proper state management
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * API PROPERTIES
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * @api recordId      {String}  Knowledge article version ID (optional)
 * @api urlName       {String}  SEO-friendly URL name for article lookup (optional)
 * @api language      {String}  Language override (defaults to user language)
 * @api showTopics    {Boolean} Controls topic links visibility (default: false)
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * CHANGELOG
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * Version 2.0.0 (2025-01-24) - Dennis van Musschenbroek
 * ─────────────────────────────────────────────────────────────────────────────────────────────────
 * - ADDED: Comprehensive header documentation following Salesforce LWC standards
 * - ADDED: Enhanced error handling with proper async/await patterns
 * - ADDED: Improved code structure with clear method separation
 * - ADDED: JSDoc documentation for all methods and properties
 * - IMPROVED: Loading state management with better user experience
 * - IMPROVED: Topic URL generation with enhanced slug creation
 * - IMPROVED: Memory management and lifecycle optimization
 * - IMPROVED: Code readability and maintainability
 * - FIXED: Potential memory leaks in loading state management
 * 
 * Version 1.0.0 (Original) - Dennis van Musschenbroek
 * ─────────────────────────────────────────────────────────────────────────────────────────────────
 * - Initial implementation with basic article display functionality
 * - Support for recordId and urlName lookup methods
 * - Basic topic link generation
 * - Simple loading and error states
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 */

// Lightning Web Components core imports
import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

// Salesforce community utilities
import basePath from '@salesforce/community/basePath';

// Apex method import
import getByRecordOrUrl from '@salesforce/apex/KnowledgeDetailsInternalController.getByRecordOrUrl';

/**
 * @description Lightning Web Component class for displaying Knowledge article details
 * @extends LightningElement
 */
export default class KnowledgeDetailsInternal extends LightningElement {
    
    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // PUBLIC API PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    
    /**
     * @api
     * @description Knowledge article record ID (Knowledge__kav version ID)
     * @type {String}
     */
    @api recordId;

    /**
     * @api
     * @description SEO-friendly URL name for article lookup
     * @type {String}
     */
    @api urlName;

    /**
     * @api
     * @description Language override (e.g., 'nl', 'en_US'). Defaults to user's language if not provided
     * @type {String}
     */
    @api language;

    /**
     * @api
     * @description Controls whether topic links are displayed
     * @type {Boolean}
     * @default false
     */
    @api showTopics = false;

    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // PRIVATE REACTIVE PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════════════════════════════

    /**
     * @description Complete article data object containing all display information
     * @type {Object|null}
     * @private
     */
    @track article = null;

    /**
     * @description Loading state indicator for UI feedback
     * @type {Boolean}
     * @default true
     * @private
     */
    @track loading = true;

    /**
     * @description Error state indicator when article cannot be loaded or found
     * @type {Boolean}
     * @default false
     * @private
     */
    @track notFound = false;

    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // WIRE SERVICES
    // ═══════════════════════════════════════════════════════════════════════════════════════════════

    /**
     * @description Wire service to capture current page reference for URL parameter extraction
     * @param {Object} pageReference Current page reference object
     */
    @wire(CurrentPageReference)
    handlePageReferenceChange(pageReference) {
        if (!pageReference) {
            return;
        }

        const state = pageReference.state || {};
        
        // Extract urlName from page state if not provided via API
        if (!this.recordId && !this.urlName && state.urlName) {
            this.urlName = state.urlName;
            // Trigger reload if we now have the urlName
            this.loadArticle();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // LIFECYCLE HOOKS
    // ═══════════════════════════════════════════════════════════════════════════════════════════════

    /**
     * @description Component lifecycle hook - called when component is inserted into DOM
     * Initiates the article loading process
     */
    connectedCallback() {
        this.loadArticle();
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS - BUSINESS LOGIC
    // ═══════════════════════════════════════════════════════════════════════════════════════════════

    /**
     * @description Loads the Knowledge article using the configured parameters
     * Handles loading states, error conditions, and data transformation
     * @private
     * @async
     */
    async loadArticle() {
        // Skip loading if no identifier is available
        if (!this.recordId && !this.urlName) {
            this.loading = false;
            this.notFound = true;
            return;
        }

        this.loading = true;
        this.notFound = false;
        this.article = null;

        try {
            // Call Apex method to retrieve article data
            const response = await getByRecordOrUrl({
                recordId: this.recordId || null,
                urlName: this.urlName || null,
                language: this.language || null
            });

            if (response && response.id) {
                // Process successful response
                this.article = this.processArticleData(response);
            } else {
                // Handle case where no article was found
                this.notFound = true;
                this.logDebugInfo(response);
            }

        } catch (error) {
            // Handle any errors during article retrieval
            this.handleLoadError(error);
        } finally {
            this.loading = false;
        }
    }

    /**
     * @description Processes raw article data from Apex and enhances with UI-specific information
     * @param {Object} rawArticleData Raw article data from Apex controller
     * @return {Object} Enhanced article data with topic URLs
     * @private
     */
    processArticleData(rawArticleData) {
        // Generate topic URLs for navigation
        const enhancedTopics = (rawArticleData.topics || []).map(topic => ({
            ...topic,
            url: this.generateTopicUrl(topic.id, topic.name)
        }));

        return {
            ...rawArticleData,
            topics: enhancedTopics
        };
    }

    /**
     * @description Generates SEO-friendly topic URLs for navigation
     * @param {String} topicId The topic ID
     * @param {String} topicName The topic name for slug generation
     * @return {String} Complete topic URL
     * @private
     */
    generateTopicUrl(topicId, topicName) {
        const slug = this.createSlug(topicName);
        return `${basePath}/topic/${topicId}/${slug}`;
    }

    /**
     * @description Creates URL-friendly slug from topic name
     * Handles special characters, accents, and ensures valid URL format
     * @param {String} name The topic name to convert
     * @return {String} URL-friendly slug
     * @private
     */
    createSlug(name) {
        if (!name) {
            return '';
        }

        return name
            .toString()
            .normalize('NFD')                           // Decompose unicode characters
            .replace(/[\u0300-\u036f]/g, '')           // Remove accent marks
            .toLowerCase()                             // Convert to lowercase
            .trim()                                    // Remove leading/trailing whitespace
            .replace(/[^a-z0-9\s-]/g, '')             // Remove special characters
            .replace(/\s+/g, '-')                     // Replace spaces with hyphens
            .replace(/-+/g, '-')                      // Replace multiple hyphens with single
            .replace(/^-+|-+$/g, '');                 // Remove leading/trailing hyphens
    }

    /**
     * @description Handles errors during article loading process
     * @param {Error} error The error object from the failed operation
     * @private
     */
    handleLoadError(error) {
        this.notFound = true;
        
        // Log error details for debugging (only in development)
        if (typeof console !== 'undefined') {
            console.error('Error loading Knowledge article:', error);
        }
        
        // Could integrate with error tracking service here
        // Example: this.reportError(error);
    }

    /**
     * @description Logs debug information when article is not found
     * @param {Object} response Response object potentially containing debug information
     * @private
     */
    logDebugInfo(response) {
        if (response && response.debugNote && typeof console !== 'undefined') {
            console.info('Article not found - Debug info:', response.debugNote);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // GETTER METHODS - COMPUTED PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════════════════════════════

    /**
     * @description Computed property to determine if topics should be displayed
     * @return {Boolean} True if topics should be shown and article has topics
     * @readonly
     */
    get shouldDisplayTopics() {
        return this.showTopics && 
               this.article && 
               this.article.topics && 
               this.article.topics.length > 0;
    }

    /**
     * @description Computed property for article availability
     * @return {Boolean} True if article data is available for display
     * @readonly
     */
    get hasArticle() {
        return this.article && this.article.id;
    }

    /**
     * @description Computed property for error state display
     * @return {Boolean} True if component should show error state
     * @readonly
     */
    get shouldShowError() {
        return !this.loading && this.notFound;
    }
}