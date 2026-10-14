import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional inventory rollup must pass. Check returns its problems, or none.
    protocol RegionalInventoryRollupRule {
        func check(_ item: RegionalInventoryRollup) -> [String]
    }

    final class RegionalInventoryRollupRequiredLabelRule: RegionalInventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInventoryRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalInventoryRollupRequiredPhoneRule: RegionalInventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInventoryRollup) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalInventoryRollupSourceLengthRule: RegionalInventoryRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalInventoryRollup) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional inventory rollup.
    final class RegionalInventoryRollupValidator {
        var rules: [any RegionalInventoryRollupRule]

        init(rules: [any RegionalInventoryRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalInventoryRollup) -> [String] {
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

        func requireValid(_ item: RegionalInventoryRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalInventoryRollup]) -> [String: [String]] {
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

    static func defaultRegionalInventoryRollupValidator() -> RegionalInventoryRollupValidator {
        return RegionalInventoryRollupValidator(
            rules: [
                RegionalInventoryRollupRequiredLabelRule(message: "regional inventory rollup needs this field"),
                RegionalInventoryRollupRequiredPhoneRule(message: "regional inventory rollup needs an entry"),
                RegionalInventoryRollupSourceLengthRule(maxLength: 255),
            ]
        )
    }
}
