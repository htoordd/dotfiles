---
description: Format the current session's research findings into Q&A entries for the support knowledge base Google Doc. Invoke after a support research session to get copy-paste-ready output.
---

# Format Support Research as Q&A

You are tasked with taking everything learned in the current conversation session and formatting it into Q&A entries that can be directly copied into the team's support knowledge base Google Doc.

## Instructions

1. **Review the entire conversation** to identify:
   - The customer's original question(s) or problem(s)
   - The answers, explanations, and solutions discovered through research
   - Any related sub-questions that came up and were answered
   - Code examples, configuration snippets, or commands that were part of the answer

2. **Break the findings into discrete Q&A pairs**:
   - Each question should be a standalone question a future support engineer might search for
   - Each answer should be self-contained and understandable without the full conversation context
   - If the research uncovered multiple distinct topics, create separate Q&A pairs for each
   - Phrase questions the way a customer or support engineer would naturally ask them
   - Keep answers concise but complete — include enough detail to be actionable
   - Include code blocks (yaml, json, go, etc.) when relevant
   - Include file paths or references when they help the reader

3. **Format using the exact Google Doc structure below** and output it in a single markdown code block so it's easy to copy.

## Output Format

The output MUST follow this exact structure. Output it inside a single markdown code block:

```
### Time Added to Doc: {current date in "DD Mon YY HH:MM UTC" format}
Documented by [Hasan Toor](mailto:hasan.toor@datadoghq.com)
#### {Question 1}
{Answer 1}
#### {Question 2}
{Answer 2}
#### {Question 3 - if applicable}
{Answer 3 - if applicable}
```

## Formatting Rules

- **Timestamp heading** (H3): `### Time Added to Doc: DD Mon YY HH:MM UTC`
  - Use the CURRENT date/time in UTC
  - Month is abbreviated 3 letters (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)
  - Year is 2 digits
  - Example: `### Time Added to Doc: 18 Feb 26 15:30 UTC`

- **Documented by** line: `Documented by [Hasan Toor](mailto:hasan.toor@datadoghq.com)`
  - Always attribute to Hasan Toor with mailto link
  - This line goes directly under the timestamp heading with no blank line

- **Questions** (H4): `#### {Question text}?`
  - Phrased as natural questions ending with `?`
  - Written from the perspective of someone encountering the issue

- **Answers**: Normal paragraph text directly under the question
  - No heading, no bullet prefix — just plain text
  - Use code blocks with language tags when including code/config/commands:
    ```yaml
    example: value
    ```
  - Keep language clear and suitable for a support audience
  - Do NOT include internal-only implementation details (file paths, internal code references) unless they are directly useful for troubleshooting
  - If referencing internal tools, Jira tickets, or Slack channels, include them as they are useful for support engineers

## Example Output

````
### Time Added to Doc: 18 Feb 26 15:30 UTC
Documented by [Hasan Toor](mailto:hasan.toor@datadoghq.com)
#### What happens when a service definition is submitted with an invalid schema version in the Software Catalog?
When a service definition is submitted with an unrecognized or invalid schema version, the Service Catalog API returns a 400 Bad Request error with a message indicating the schema version is not supported. Valid schema versions are `v2`, `v2.1`, `v2.2`, and `v3`. Ensure your definition file specifies one of these versions in the `apiVersion` field.
#### How can I migrate a service definition from v2.2 to v3 schema?
To migrate from v2.2 to v3, update the `apiVersion` field to `v3` and restructure the definition to match the v3 format. Key changes include:
- The `team` field is replaced by `metadata.owner` (single owner) and `metadata.additionalOwners` (multiple owners)
- The `kind` field is now required (e.g., `service`, `queue`, `database`)
- Links are moved under `metadata.links`

Example v3 definition:

```yaml
apiVersion: v3
kind: service
metadata:
  name: my-service
  owner: my-team
spec:
  lifecycle: production
  tier: tier1
```
````

## Process

1. Read through the full conversation history
2. Identify all distinct questions and answers
3. Craft clear, standalone Q&A pairs
4. Format them using the exact template above
5. Present the formatted output in a single code block for easy copying
6. Ask if the user wants to adjust any of the Q&A pairs before copying
