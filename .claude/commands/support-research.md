---
description: Deep research to solve customer support issues. Paste in context from a support channel and get thorough codebase and web research to help answer the query.
---

# Support Issue Research

You are tasked with performing deep research to help solve a customer support issue. You will investigate the codebase, search the web, and synthesize findings into a clear, actionable answer.

## Initial Response

When this command is invoked:

1. **Check if context was provided as a parameter**:
   - If support context was pasted inline, immediately begin analysis
   - If a file path was provided, read it fully

2. **If no context was provided**, respond with:

```
I'll help you research and resolve a customer support issue.

Please paste the relevant context from the support channel, including:
- The customer's question or problem description
- Any error messages, logs, or screenshots mentioned
- Product area or feature involved (if known)
- Any troubleshooting already attempted

I'll perform deep research across the codebase and web to help find an answer.
```

Then wait for the user's input.

## Research Process

### Step 1: Understand the Problem

1. **Parse the support context** to identify:
   - The core question or problem
   - Product area / feature / service involved
   - Specific error messages, codes, or symptoms
   - Customer's environment details (if mentioned)
   - What has already been tried

2. **Restate your understanding** concisely:

```
Here's my understanding of the issue:
- **Problem**: [1-2 sentence summary]
- **Product area**: [feature/service involved]
- **Key symptoms**: [errors, behaviors observed]
- **Already tried**: [any prior troubleshooting]

Let me research this now.
```

### Step 2: Parallel Deep Research

Launch multiple research tasks in parallel to maximize coverage:

#### Codebase Research

- Use **codebase-locator** agent to find files related to the product area / feature
- Use **codebase-pattern-finder** agent to find relevant implementation details, error handling, and edge cases
- IMPORTANT: if we are researching in `web-ui`, you will use the `codebase-locator-ts` and `codebase-pattern-finder-ts` and if we are researching in `dd-source`, you will use `codebase-locator-go` and `codebase-pattern-finder-go`.
- Use **Explore** agent for broader investigation if the area is unclear
- Search for:
  - Error messages mentioned in the support context (exact string matches)
  - Feature flags, configuration options, or settings related to the issue
  - Known limitations, TODOs, or documented quirks
  - Recent changes to the relevant code (git log)
  - Test cases that exercise the relevant behavior
  - Comments or documentation explaining the expected behavior

#### Web Research (when applicable)

- Search for the error message or symptom to find:
  - Known issues or bug reports
  - Documentation pages that explain the feature/behavior
  - Related discussions or solutions
- Search Datadog documentation for the relevant feature
- Look for related GitHub issues if applicable

### Step 3: Deep Dive

After initial research completes:

1. **Read all identified files fully** into context
2. **Trace the code path** related to the issue:
   - Follow the execution flow from API/entry point to the relevant logic
   - Identify where the reported behavior originates
   - Look for edge cases, race conditions, or configuration-dependent behavior
3. **Check recent changes** with git log on relevant files if the issue might be a regression
4. **Spawn follow-up research tasks** if initial findings raise new questions

### Step 4: Synthesize and Present Findings

Present your findings in this structure:

```
## Research Findings

### Root Cause / Explanation
[Clear explanation of what's happening and why, with code references]

### Relevant Code
- `path/to/file.go:123` - [what this code does and why it matters]
- `path/to/config.go:45` - [relevant configuration or setting]

### Answer for the Customer
[A draft response suitable for sharing back in the support channel. Written in clear, non-internal language. Includes:]
- Explanation of the behavior
- Recommended solution or workaround
- Any relevant documentation links
- Configuration changes needed (if applicable)

### Additional Context (Internal Only)
[Information useful for the support engineer but not for the customer:]
- Related feature flags
- Known limitations or tech debt
- Recent code changes that may be relevant
- Suggested internal follow-ups (bug fix, doc update, etc.)

### Confidence Level
[High / Medium / Low] - [brief explanation of confidence and any caveats]

### Open Questions
[Anything you couldn't determine from research that might need escalation or further investigation]
```

## Important Guidelines

1. **Be Thorough**: Cast a wide net initially, then narrow down. It's better to over-research than to miss the root cause.

2. **Show Your Work**: Include specific file:line references so the support engineer can verify your findings and learn the codebase.

3. **Separate Internal vs. External**: Always clearly separate what can be shared with the customer from internal implementation details.

4. **Be Honest About Uncertainty**: If you're not confident in your findings, say so. A wrong answer is worse than "I need more information."

5. **Think About Workarounds**: Even if you can't identify the root cause, suggest potential workarounds based on your understanding of the system.

6. **Check for Recency**: If the issue might be a regression, check git history on relevant files.

7. **Consider Configuration**: Many issues stem from misconfiguration. Look for relevant config options, feature flags, and environment-specific behavior.

8. **Parallel Research**: Always launch multiple research tasks in parallel to maximize speed. Don't sequentially research when you can parallelize.

9. **Draft Customer-Friendly Responses**: The support engineer should be able to copy/adapt your "Answer for the Customer" section directly into the support channel.
