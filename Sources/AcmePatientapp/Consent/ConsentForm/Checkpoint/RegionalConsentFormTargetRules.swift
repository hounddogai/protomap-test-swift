import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional consent form target must pass. Check returns its problems, or none.
    protocol RegionalConsentFormTargetRule {
        func check(_ item: RegionalConsentFormTarget) -> [String]
    }

    final class RegionalConsentFormTargetCodePrefixRule: RegionalConsentFormTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalConsentFormTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalConsentFormTargetRequiredCodeRule: RegionalConsentFormTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalConsentFormTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalConsentFormTargetPriorityRangeRule: RegionalConsentFormTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalConsentFormTarget) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalConsentFormTargetWeightRangeRule: RegionalConsentFormTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalConsentFormTarget) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional consent form target.
    final class RegionalConsentFormTargetValidator {
        var rules: [any RegionalConsentFormTargetRule]

        init(rules: [any RegionalConsentFormTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalConsentFormTarget) -> [String] {
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

        func requireValid(_ item: RegionalConsentFormTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalConsentFormTarget]) -> [String: [String]] {
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

    static func defaultRegionalConsentFormTargetValidator() -> RegionalConsentFormTargetValidator {
        return RegionalConsentFormTargetValidator(
            rules: [
                RegionalConsentFormTargetCodePrefixRule(prefix: "X"),
                RegionalConsentFormTargetRequiredCodeRule(message: "regional consent form target needs this field"),
                RegionalConsentFormTargetPriorityRangeRule(min: 80, max: 80),
                RegionalConsentFormTargetWeightRangeRule(min: 2.7, max: 4354.2),
            ]
        )
    }
}
