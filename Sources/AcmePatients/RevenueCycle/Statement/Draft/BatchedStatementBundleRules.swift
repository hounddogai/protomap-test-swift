import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched statement bundle must pass. Check returns its problems, or none.
    protocol BatchedStatementBundleRule {
        func check(_ item: BatchedStatementBundle) -> [String]
    }

    final class BatchedStatementBundleTitleLengthRule: BatchedStatementBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStatementBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStatementBundleRequiredTitleRule: BatchedStatementBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStatementBundleRequiredBedRule: BatchedStatementBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementBundle) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched statement bundle.
    final class BatchedStatementBundleValidator {
        var rules: [any BatchedStatementBundleRule]

        init(rules: [any BatchedStatementBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedStatementBundle) -> [String] {
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

        func requireValid(_ item: BatchedStatementBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedStatementBundle]) -> [String: [String]] {
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

    static func defaultBatchedStatementBundleValidator() -> BatchedStatementBundleValidator {
        return BatchedStatementBundleValidator(
            rules: [
                BatchedStatementBundleTitleLengthRule(maxLength: 32),
                BatchedStatementBundleRequiredTitleRule(message: "batched statement bundle needs an entry"),
                BatchedStatementBundleRequiredBedRule(message: "batched statement bundle needs a value"),
            ]
        )
    }
}
