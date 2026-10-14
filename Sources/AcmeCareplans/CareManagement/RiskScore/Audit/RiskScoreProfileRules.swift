import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score profile must pass. Check returns its problems, or none.
    protocol RiskScoreProfileRule {
        func check(_ item: RiskScoreProfile) -> [String]
    }

    final class RiskScoreProfileAllowedNameRule: RiskScoreProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class RiskScoreProfileRequiredSegmentRule: RiskScoreProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreProfile) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreProfileCodePrefixRule: RiskScoreProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreProfileWeightRangeRule: RiskScoreProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreProfile) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score profile.
    final class RiskScoreProfileValidator {
        var rules: [any RiskScoreProfileRule]

        init(rules: [any RiskScoreProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreProfile) -> [String] {
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

        func requireValid(_ item: RiskScoreProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreProfile]) -> [String: [String]] {
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

    static func defaultRiskScoreProfileValidator() -> RiskScoreProfileValidator {
        return RiskScoreProfileValidator(
            rules: [
                RiskScoreProfileAllowedNameRule(allowed: []),
                RiskScoreProfileRequiredSegmentRule(message: "risk score profile needs an entry"),
                RiskScoreProfileCodePrefixRule(prefix: "ACM"),
                RiskScoreProfileWeightRangeRule(min: 1.9, max: 2401.0),
            ]
        )
    }
}
