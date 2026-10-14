import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal isolation rule must pass. Check returns its problems, or none.
    protocol SeasonalIsolationRuleRule {
        func check(_ item: SeasonalIsolationRule) -> [String]
    }

    final class SeasonalIsolationRuleCopayRangeRule: SeasonalIsolationRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalIsolationRule) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalIsolationRuleLabelLengthRule: SeasonalIsolationRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalIsolationRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalIsolationRuleCodeLengthRule: SeasonalIsolationRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalIsolationRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalIsolationRuleDiagnosisCodeLengthRule: SeasonalIsolationRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalIsolationRule) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalIsolationRuleRequiredLabelRule: SeasonalIsolationRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalIsolationRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal isolation rule.
    final class SeasonalIsolationRuleValidator {
        var rules: [any SeasonalIsolationRuleRule]

        init(rules: [any SeasonalIsolationRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalIsolationRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalIsolationRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalIsolationRule]) -> [String: [String]] {
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

    static func defaultSeasonalIsolationRuleValidator() -> SeasonalIsolationRuleValidator {
        return SeasonalIsolationRuleValidator(
            rules: [
                SeasonalIsolationRuleCopayRangeRule(min: 4.8, max: 4797.9),
                SeasonalIsolationRuleLabelLengthRule(maxLength: 32),
                SeasonalIsolationRuleCodeLengthRule(maxLength: 120),
                SeasonalIsolationRuleDiagnosisCodeLengthRule(maxLength: 64),
                SeasonalIsolationRuleRequiredLabelRule(message: "seasonal isolation rule needs a value"),
            ]
        )
    }
}
