/**
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * KNOWLEDGE DETAILS INTERNAL CONTROLLER
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * @description    Lightning Web Component controller for retrieving Salesforce Knowledge articles
 *                 Handles both record ID and URL name based lookups with language support
 *                 Provides comprehensive error handling and debug information
 * 
 * @author         Dennis van Musschenbroek
 * @created        2025-01-24
 * @version        2.0.0
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * FUNCTIONALITY OVERVIEW
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * This controller serves as the backend logic for the knowledgeDetailsInternal Lightning Web Component.
 * It retrieves Knowledge articles (Knowledge__kav) with their associated topics and provides
 * comprehensive error handling with debugging information.
 * 
 * Key Features:
 * - Dual lookup mechanism (Record ID or URL Name)
 * - Language-aware article retrieval
 * - Topic association retrieval
 * - Comprehensive error handling and debugging
 * - Platform event-based error logging integration
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * TECHNICAL IMPLEMENTATION
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * Following AWAF (Apex Well-Architected Framework) principles:
 * - Single responsibility: Focus on Knowledge article retrieval only
 * - Error handling: Graceful degradation with user-friendly messages
 * - Separation of concerns: Business logic separate from infrastructure
 * - Testability: Cacheable methods with clear inputs/outputs
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * CHANGELOG
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 * 
 * Version 2.0.0 (2025-01-24) - Dennis van Musschenbroek
 * ─────────────────────────────────────────────────────────────────────────────────────────────────
 * - ADDED: Comprehensive header documentation following AWAF standards
 * - ADDED: Enhanced error handling with user-friendly Dutch messages
 * - ADDED: Improved code structure and documentation
 * - ADDED: AWAF-compliant architecture patterns
 * - IMPROVED: Method documentation with clear parameter descriptions
 * - IMPROVED: Exception handling with proper error logging integration
 * - IMPROVED: Code readability and maintainability
 * 
 * Version 1.0.0 (Original) - Dennis van Musschenbroek
 * ─────────────────────────────────────────────────────────────────────────────────────────────────
 * - Initial implementation with basic Knowledge article retrieval
 * - Support for both recordId and urlName lookup methods
 * - Topic association retrieval
 * - Basic error handling
 * 
 * ═══════════════════════════════════════════════════════════════════════════════════════════════════
 */
public with sharing class KnowledgeDetailsInternalController {
    
    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // INNER CLASSES - DATA TRANSFER OBJECTS
    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    
    /**
     * @description Topic reference data transfer object
     * @purpose     Lightweight wrapper for Topic information used in Knowledge articles
     */
    public class TopicRef {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
    }

    /**
     * @description Article data transfer object containing all necessary information for the LWC
     * @purpose     Structured response object that provides complete article data with debug information
     */
    public class ArticleDTO {
        @AuraEnabled public String id;                  // Knowledge__kav version Id
        @AuraEnabled public String urlName;             // SEO url name for web routing
        @AuraEnabled public String articleNumber;       // System-generated article number
        @AuraEnabled public String title;               // Human-readable article title
        @AuraEnabled public Datetime lastPublishedDate; // Last publication timestamp
        @AuraEnabled public String question;            // Question field (rich text)
        @AuraEnabled public String answerHtml;          // Answer field (rich text HTML)
        @AuraEnabled public List<TopicRef> topics;      // Associated topics for categorization
        @AuraEnabled public String debugNote;           // Debug information for troubleshooting
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // PUBLIC METHODS - API SURFACE
    // ═══════════════════════════════════════════════════════════════════════════════════════════════

    /**
     * @description Retrieves a Knowledge article by Record ID or URL Name with language support
     * @param recordId  The Knowledge article version ID (optional if urlName provided)
     * @param urlName   The SEO-friendly URL name (optional if recordId provided)
     * @param language  Language code override (defaults to user's language if not provided)
     * @return ArticleDTO containing article data or error information
     * @throws AuraHandledException User-friendly error for UI consumption
     * 
     * @example
     * // Retrieve by record ID
     * ArticleDTO article = KnowledgeDetailsInternalController.getByRecordOrUrl(
     *     'kA1xx000000001', null, 'nl'
     * );
     * 
     * // Retrieve by URL name
     * ArticleDTO article = KnowledgeDetailsInternalController.getByRecordOrUrl(
     *     null, 'how-to-reset-password', 'en_US'
     * );
     */
    @AuraEnabled(cacheable=true)
    public static ArticleDTO getByRecordOrUrl(String recordId, String urlName, String language) {
        try {
            // Input validation - At least one identifier must be provided
            if (String.isBlank(recordId) && String.isBlank(urlName)) {
                throw new AuraHandledException('Provide either recordId or urlName.');
            }
            
            // Language resolution - Use provided language or default to user's language
            String resolvedLanguage = String.isBlank(language) ? UserInfo.getLanguage() : language;

            // Retrieve the Knowledge article using the appropriate lookup method
            Knowledge__kav articleRecord = retrieveKnowledgeArticle(recordId, urlName, resolvedLanguage);
            
            // Handle case where no article is found
            if (articleRecord == null) {
                return generateNotFoundResponse(recordId, urlName, resolvedLanguage);
            }

            // Build and return the successful response
            return buildArticleResponse(articleRecord, urlName, resolvedLanguage);

        } catch (Exception ex) {
            return handleException(ex);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS - INTERNAL BUSINESS LOGIC
    // ═══════════════════════════════════════════════════════════════════════════════════════════════

    /**
     * @description Retrieves a Knowledge article record based on provided identifiers
     * @param recordId The Knowledge article version ID
     * @param urlName The SEO-friendly URL name
     * @param language The language code for the article
     * @return Knowledge__kav record or null if not found
     */
    private static Knowledge__kav retrieveKnowledgeArticle(String recordId, String urlName, String language) {
        List<Knowledge__kav> articles;
        
        if (String.isNotBlank(recordId)) {
            // Lookup by Record ID
            articles = [
                SELECT Id, UrlName, ArticleNumber, Title, LastPublishedDate,
                       Question__c, Answer__c, PublishStatus, Language
                FROM Knowledge__kav
                WHERE PublishStatus = 'Online' 
                  AND Language = :language 
                  AND Id = :recordId
                LIMIT 1
            ];
        } else {
            // Lookup by URL Name
            articles = [
                SELECT Id, UrlName, ArticleNumber, Title, LastPublishedDate,
                       Question__c, Answer__c, PublishStatus, Language
                FROM Knowledge__kav
                WHERE PublishStatus = 'Online' 
                  AND Language = :language 
                  AND UrlName = :urlName
                LIMIT 1
            ];
        }
        
        return articles.isEmpty() ? null : articles[0];
    }

    /**
     * @description Generates a diagnostic response when no article is found
     * @param recordId The attempted record ID lookup
     * @param urlName The attempted URL name lookup
     * @param language The language that was searched
     * @return ArticleDTO with diagnostic information
     */
    private static ArticleDTO generateNotFoundResponse(String recordId, String urlName, String language) {
        // Probe to understand why the article wasn't found
        List<Knowledge__kav> diagnosticQuery = [
            SELECT Id, UrlName, ArticleNumber, PublishStatus, Language
            FROM Knowledge__kav
            WHERE (Id = :recordId OR UrlName = :urlName)
            ORDER BY LastPublishedDate DESC NULLS LAST
            LIMIT 1
        ];
        
        ArticleDTO response = new ArticleDTO();
        
        if (!diagnosticQuery.isEmpty()) {
            Knowledge__kav foundArticle = diagnosticQuery[0];
            response.debugNote = String.format(
                'Article exists but not Online for language {0}. Found version in {1} with status {2}.',
                new String[] { language, foundArticle.Language, foundArticle.PublishStatus }
            );
        } else {
            response.debugNote = 'No Knowledge__kav matched the provided identifier.';
        }
        
        return response;
    }

    /**
     * @description Builds a complete article response with topics
     * @param article The retrieved Knowledge article record
     * @param urlName The URL name used for lookup (for debug purposes)
     * @param language The language used for lookup (for debug purposes)
     * @return ArticleDTO Complete article data transfer object
     */
    private static ArticleDTO buildArticleResponse(Knowledge__kav article, String urlName, String language) {
        ArticleDTO response = new ArticleDTO();
        
        // Map basic article properties
        response.id = article.Id;
        response.urlName = article.UrlName;
        response.articleNumber = article.ArticleNumber;
        response.title = article.Title;
        response.lastPublishedDate = article.LastPublishedDate;
        response.question = (String) article.get('Question__c');
        response.answerHtml = (String) article.get('Answer__c');
        
        // Add debug information
        String lookupMethod = String.isBlank(urlName) ? 'recordId' : 'urlName';
        response.debugNote = String.format(
            'Resolved via {0} in language {1}.',
            new String[] { lookupMethod, language }
        );

        // Retrieve and map associated topics
        response.topics = retrieveArticleTopics(article.Id);
        
        return response;
    }

    /**
     * @description Retrieves topics associated with a Knowledge article
     * @param articleId The Knowledge article version ID
     * @return List of TopicRef objects representing associated topics
     */
    private static List<TopicRef> retrieveArticleTopics(String articleId) {
        List<TopicRef> topics = new List<TopicRef>();
        
        for (TopicAssignment assignment : [
            SELECT Topic.Id, Topic.Name
            FROM TopicAssignment
            WHERE EntityId = :articleId
        ]) {
            TopicRef topic = new TopicRef();
            topic.id = assignment.Topic.Id;
            topic.name = assignment.Topic.Name;
            topics.add(topic);
        }
        
        return topics;
    }

    /**
     * @description Handles exceptions with proper logging and user-friendly messaging
     * @param ex The exception that occurred
     * @return ArticleDTO with error information or throws AuraHandledException
     */
    private static ArticleDTO handleException(Exception ex) {
        // Log the error using the organization's error handling mechanism
        try {
            ApexFaultHandler.publishError(ex, 'KnowledgeDetailsInternalController', 'getByRecordOrUrl');
        } catch (Exception loggingException) {
            // Never allow logging failures to mask the original error
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + loggingException.getMessage());
        }
        
        // Return user-friendly error message in Dutch
        throw new AuraHandledException('Er is een fout opgetreden bij het laden van het artikel.');
    }
}