import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional order set rollup must pass. Check returns its problems, or none.
    protocol RegionalOrderSetRollupRule {
        func check(_ item: RegionalOrderSetRollup) -> [String]
    }

    final class RegionalOrderSetRollupNameLengthRule: RegionalOrderSetRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOrderSetRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOrderSetRollupRequiredCodeRule: RegionalOrderSetRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOrderSetRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOrderSetRollupRequiredLabelRule: RegionalOrderSetRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOrderSetRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional order set rollup.
    final class RegionalOrderSetRollupValidator {
        var rules: [any RegionalOrderSetRollupRule]

        init(rules: [any RegionalOrderSetRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOrderSetRollup) -> [String] {
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

        func requireValid(_ item: RegionalOrderSetRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOrderSetRollup]) -> [String: [String]] {
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

    static func defaultRegionalOrderSetRollupValidator() -> RegionalOrderSetRollupValidator {
        return RegionalOrderSetRollupValidator(
            rules: [
                RegionalOrderSetRollupNameLengthRule(maxLength: 32),
                RegionalOrderSetRollupRequiredCodeRule(message: "regional order set rollup needs a value"),
                RegionalOrderSetRollupRequiredLabelRule(message: "regional order set rollup needs a value"),
            ]
        )
    }
}
