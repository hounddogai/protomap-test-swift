import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched disclosure request must pass. Check returns its problems, or none.
    protocol BatchedDisclosureRequestRule {
        func check(_ item: BatchedDisclosureRequest) -> [String]
    }

    final class BatchedDisclosureRequestRequiredSpecialtyRule: BatchedDisclosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDisclosureRequest) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDisclosureRequestReviewerLengthRule: BatchedDisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDisclosureRequest) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDisclosureRequestRequiredTitleRule: BatchedDisclosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDisclosureRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDisclosureRequestRetriesRangeRule: BatchedDisclosureRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDisclosureRequest) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched disclosure request.
    final class BatchedDisclosureRequestValidator {
        var rules: [any BatchedDisclosureRequestRule]

        init(rules: [any BatchedDisclosureRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDisclosureRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDisclosureRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDisclosureRequest]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultBatchedDisclosureRequestValidator() -> BatchedDisclosureRequestValidator {
        return BatchedDisclosureRequestValidator(
            rules: [
                BatchedDisclosureRequestRequiredSpecialtyRule(message: "batched disclosure request needs a value"),
                BatchedDisclosureRequestReviewerLengthRule(maxLength: 120),
                BatchedDisclosureRequestRequiredTitleRule(message: "batched disclosure request needs a value"),
                BatchedDisclosureRequestRetriesRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
