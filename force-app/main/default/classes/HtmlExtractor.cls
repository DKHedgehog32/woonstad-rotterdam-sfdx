public class HtmlExtractor {

    public class Input {
        @InvocableVariable(required=true)
        public String richTextContent;
        
        @InvocableVariable(required=true)
        public String elementId;
    }

    public class Output {
        @InvocableVariable
        public List<String> extractedHtmlCollection;
    }

    @InvocableMethod(label='Extract HTML by ID' description='Extract all HTML elements by ID from a given rich text content')
    public static List<Output> extractHtml(List<Input> inputList) {
        List<Output> results = new List<Output>();
        try {
            for (Input input : inputList) {
                Output result = new Output();
                result.extractedHtmlCollection = new List<String>();

                String regex = '(?s)<([a-zA-Z0-9]+)[^>]*\\bid=["\']' + input.elementId + '["\'][^>]*>(.*?)</\\1>';
                Pattern pattern = Pattern.compile(regex);
                Matcher matcher = pattern.matcher(input.richTextContent);

                while (matcher.find()) {
                    result.extractedHtmlCollection.add(matcher.group(0));
                }

                results.add(result);
            }
        } catch (Exception e) {
            ApexFaultHandler.publishError(e, 'HtmlExtractor', 'extractHtml');
        }
        return results;
    }
}