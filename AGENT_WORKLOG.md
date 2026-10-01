# Agent worklog

I used Claude Code for this task. First, I asked it to go through the whole
codebase of this project and explain what had already been done and what still
needed to be done. Then I asked it to explain the homework tasks in simple
words and to write detailed instructions on how to implement them.

After that, I started working on the tasks one by one, asking for explanations
of unfamiliar theory and of the parts of the code that were new to me. Then I
asked it to write the code, but I rejected the option of letting it make
changes directly in my folders. Instead, I asked it to write the code in the
chat so that I could copy it myself, because I feel more confident about what
the agent is doing that way. Finally, I asked it to explain what had been done.

I followed this same process for every task. For the last task, writing my own
tests, I asked it to explain the public tests to me in detail. Then I
explained what I wanted to see in my own tests: what I wanted to cover, that I
wanted them to follow the AAA (Arrange–Act–Assert) structure, and which edge
cases I wanted to test. It wrote the tests for me, and I copied, pasted and
ran them. After that, I asked it to change some logic in my code to check
whether the tests really caught mistakes, and I got the expected failure.

For `PLAN.md` and this file, I first wrote down my own stream of thoughts,
with mistakes and all, and then asked the agent to correct the grammar and
improve the structure without changing the meaning.

## Task 1 StudyItem validation

### Tool/agent task

Asked Claude Code to explain assignment and Task 1 step by step:
`guard`/`throw`, blank-title detection with `trimmingCharacters(in: .whitespacesAndNewlines)`,
and why the title must be checked before the minutes.

### Output reviewed

- Suggested code for `StudyItem.init` in `Sources/StudyPlanner/StudyPlanner.swift`.
- Explanation of why the full `swift test` run crashes (`fatalError` in `StudyPlan`).

### Accepted/rejected/revised decision

- Accepted: the validation logic. I typed it myself and checked it against the requirements.
- Accepted: storing the original (untrimmed) title.
- Revised: fixed inconsistent indentation in my first version.
- Rejected: letting the assistant edit files directly; I made all changes myself.

### Verification command/result

`swift test --filter "testValidItemStoresValues|testBlankTitleIsRejected"` 

### Artifact links

None for this step. The final test run is in `artifacts/swift-test-final.txt`.

## Task 2 Codable boundaries

### Tool/agent task

Asked Claude Code to explain why Swift's automatic Codable skips my
validation, and how to write `init(from decoder:)` for `StudyItem` and
`StudyPlan` and the body of `StudyPlan.decode(from:)`.

### Output reviewed

The suggested code for both `init(from decoder:)` methods, the `CodingKeys`
enums and `decode(from:)`, plus the advice to put a temporary
`self.items = items` into `init(items:)` so Task 2 can be built and checked
before Task 3.

### Accepted/rejected/revised decision

I accepted the decoding code and typed it in myself. I accepted the temporary
`init(items:)` and wrote it down as a risk in `PLAN.md`, so I remember to
replace it in Task 3. I chose to treat a missing `isCompleted` as `false`, to
match the default in the normal initializer.

### Verification command/result

`swift build` -> `Build complete!`. The full `swift test` still stopped at an unfinished function from a later task.

### Artifact links

None for this step. The final test run is in `artifacts/swift-test-final.txt`.

## Task 3 Duplicates and ordering

### Tool/agent task

Asked Claude Code to explain how to report the first duplicate id and how to
sort items by title and then by id in `StudyPlan.init(items:)`.

### Output reviewed

The suggested loop with a `Set<String>` for seen ids, the `sorted` call that
compares `(title, id)` tuples, and the explanation why duplicates must be
checked before sorting.

### Accepted/rejected/revised decision

I accepted the duplicate check and the tuple sorting and typed them in myself.
I removed the temporary `self.items = items` from Task 2. I kept Swift's
default case-sensitive string comparison and wrote this down as a risk in
`PLAN.md`.

### Verification command/result

`swift build` -> `Build complete!`. The full `swift test` still stopped at an unfinished function from a later task.

### Artifact links

None for this step. The final test run is in `artifacts/swift-test-final.txt`.

## Task 4 Queries and completion

### Tool/agent task

Asked Claude Code to explain `filter`, `reduce` and `firstIndex`, how to
implement `items(in:)`, `incompleteMinutes()` and `markCompleted(id:)`, and
how to change `isCompleted` when it is `private(set)`.

### Output reviewed

The suggested code for the three `StudyPlan` methods and the internal
`markAsCompleted()` helper in `StudyItem`, and the explanation of idempotent
completion.

### Accepted/rejected/revised decision

I accepted the code and typed it in myself. I kept `markAsCompleted()`
internal (no `public`) so the public API doesn't change. I also moved my
`Scope` section from `TASKS_AND_GRADES.md` to `PLAN.md`, because I had put it
in the wrong file.

### Verification command/result

`swift test` -> 6 tests, 0 failures. This was the first full run without a crash.

### Artifact links

None for this step. The final test run is in `artifacts/swift-test-final.txt`.

## Task 5 My tests

### Tool/agent task

I asked Claude Code to explain the
public tests to me in detail. Then I explained what I wanted to see in my own
tests: what I wanted to cover, that I wanted them to follow the AAA
(Arrange–Act–Assert) structure, and which edge cases I wanted to test.

### Output reviewed

It wrote the tests for me based on what I described, and I copied, pasted and
ran them.

### Accepted/rejected/revised decision

I accepted the tests. After that, I asked it to change some logic in my code to
check whether the tests really caught mistakes, and I got the expected
failure. Then I put the code back. 

### Verification command/result

`swift test` -> 15 tests, 0 failures (12 of my tests and 3 starter tests).

### Artifact links

The final test run is in `artifacts/swift-test-final.txt`.

## Bonus importMerging

### Tool/agent task

I asked Claude Code to explain the bonus rules in simple words with an
example, what "atomic" means, and how to implement `importMerging`.

### Output reviewed

An explanation with a before/after example, the suggested code that checks
duplicates first and works on a copy, and three suggested tests.

### Accepted/rejected/revised decision

I accepted the code, but not tests, asked him to change them. Also he explained to me risk and I typed it in my Plan.

### Verification command/result

`swift test` -> 18 tests, 0 failures.

### Artifact links

The final test run is in `artifacts/swift-test-final.txt`.
