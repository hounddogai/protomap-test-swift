import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered read batch must pass. Check returns its problems, or none.
    protocol TieredReadBatchRule {
        func check(_ item: TieredReadBatch) -> [String]
    }

    final class TieredReadBatchCountryLengthRule: TieredReadBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadBatch) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadBatchCodePrefixRule: TieredReadBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredReadBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredReadBatchLabelLengthRule: TieredReadBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadBatchRequiredCodeRule: TieredReadBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered read batch.
    final class TieredReadBatchValidator {
        var rules: [any TieredReadBatchRule]

        init(rules: [any TieredReadBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReadBatch) -> [String] {
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

        func requireValid(_ item: TieredReadBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReadBatch]) -> [String: [String]] {
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

    static func defaultTieredReadBatchValidator() -> TieredReadBatchValidator {
        return TieredReadBatchValidator(
            rules: [
                TieredReadBatchCountryLengthRule(maxLength: 86400),
                TieredReadBatchCodePrefixRule(prefix: "Q"),
                TieredReadBatchLabelLengthRule(maxLength: 3600),
                TieredReadBatchRequiredCodeRule(message: "tiered read batch needs an entry"),
            ]
        )
    }
}
