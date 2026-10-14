import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal handoff policy must pass. Check returns its problems, or none.
    protocol SeasonalHandoffPolicyRule {
        func check(_ item: SeasonalHandoffPolicy) -> [String]
    }

    final class SeasonalHandoffPolicyWardLengthRule: SeasonalHandoffPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffPolicy) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffPolicyFacilityLengthRule: SeasonalHandoffPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffPolicy) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffPolicyRequiredFacilityRule: SeasonalHandoffPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalHandoffPolicy) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalHandoffPolicyCodeLengthRule: SeasonalHandoffPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffPolicyRequiredCodeRule: SeasonalHandoffPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalHandoffPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal handoff policy.
    final class SeasonalHandoffPolicyValidator {
        var rules: [any SeasonalHandoffPolicyRule]

        init(rules: [any SeasonalHandoffPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalHandoffPolicy) -> [String] {
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

        func requireValid(_ item: SeasonalHandoffPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalHandoffPolicy]) -> [String: [String]] {
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

    static func defaultSeasonalHandoffPolicyValidator() -> SeasonalHandoffPolicyValidator {
        return SeasonalHandoffPolicyValidator(
            rules: [
                SeasonalHandoffPolicyWardLengthRule(maxLength: 86400),
                SeasonalHandoffPolicyFacilityLengthRule(maxLength: 3600),
                SeasonalHandoffPolicyRequiredFacilityRule(message: "seasonal handoff policy needs a value"),
                SeasonalHandoffPolicyCodeLengthRule(maxLength: 255),
                SeasonalHandoffPolicyRequiredCodeRule(message: "seasonal handoff policy needs an entry"),
            ]
        )
    }
}
