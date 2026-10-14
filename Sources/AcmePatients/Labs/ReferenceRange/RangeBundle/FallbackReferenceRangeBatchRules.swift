import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback reference range batch must pass. Check returns its problems, or none.
    protocol FallbackReferenceRangeBatchRule {
        func check(_ item: FallbackReferenceRangeBatch) -> [String]
    }

    final class FallbackReferenceRangeBatchRequiredLabelRule: FallbackReferenceRangeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferenceRangeBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReferenceRangeBatchRequiredTitleRule: FallbackReferenceRangeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferenceRangeBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReferenceRangeBatchCodeLengthRule: FallbackReferenceRangeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferenceRangeBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeBatchCodePrefixRule: FallbackReferenceRangeBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackReferenceRangeBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeBatchLabelLengthRule: FallbackReferenceRangeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferenceRangeBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback reference range batch.
    final class FallbackReferenceRangeBatchValidator {
        var rules: [any FallbackReferenceRangeBatchRule]

        init(rules: [any FallbackReferenceRangeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReferenceRangeBatch) -> [String] {
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

        func requireValid(_ item: FallbackReferenceRangeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReferenceRangeBatch]) -> [String: [String]] {
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

    static func defaultFallbackReferenceRangeBatchValidator() -> FallbackReferenceRangeBatchValidator {
        return FallbackReferenceRangeBatchValidator(
            rules: [
                FallbackReferenceRangeBatchRequiredLabelRule(message: "fallback reference range batch needs a value"),
                FallbackReferenceRangeBatchRequiredTitleRule(message: "fallback reference range batch needs a value"),
                FallbackReferenceRangeBatchCodeLengthRule(maxLength: 86400),
                FallbackReferenceRangeBatchCodePrefixRule(prefix: "X"),
                FallbackReferenceRangeBatchLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
