import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal transfer policy must pass. Check returns its problems, or none.
    protocol SeasonalTransferPolicyRule {
        func check(_ item: SeasonalTransferPolicy) -> [String]
    }

    final class SeasonalTransferPolicyRequiredUnitRule: SeasonalTransferPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalTransferPolicy) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalTransferPolicyTitleLengthRule: SeasonalTransferPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalTransferPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalTransferPolicyRequiredCodeRule: SeasonalTransferPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalTransferPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalTransferPolicyRefillsRangeRule: SeasonalTransferPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalTransferPolicy) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal transfer policy.
    final class SeasonalTransferPolicyValidator {
        var rules: [any SeasonalTransferPolicyRule]

        init(rules: [any SeasonalTransferPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalTransferPolicy) -> [String] {
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

        func requireValid(_ item: SeasonalTransferPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalTransferPolicy]) -> [String: [String]] {
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

    static func defaultSeasonalTransferPolicyValidator() -> SeasonalTransferPolicyValidator {
        return SeasonalTransferPolicyValidator(
            rules: [
                SeasonalTransferPolicyRequiredUnitRule(message: "seasonal transfer policy needs this field"),
                SeasonalTransferPolicyTitleLengthRule(maxLength: 80),
                SeasonalTransferPolicyRequiredCodeRule(message: "seasonal transfer policy needs a value"),
                SeasonalTransferPolicyRefillsRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
