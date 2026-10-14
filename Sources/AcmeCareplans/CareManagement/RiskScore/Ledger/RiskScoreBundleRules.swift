import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score bundle must pass. Check returns its problems, or none.
    protocol RiskScoreBundleRule {
        func check(_ item: RiskScoreBundle) -> [String]
    }

    final class RiskScoreBundleAllowedCategoryRule: RiskScoreBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is too long"]
            }
            return []
        }
    }

    final class RiskScoreBundleCodePrefixRule: RiskScoreBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreBundleRequiredNameRule: RiskScoreBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreBundleDosageMgRangeRule: RiskScoreBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreBundle) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score bundle.
    final class RiskScoreBundleValidator {
        var rules: [any RiskScoreBundleRule]

        init(rules: [any RiskScoreBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreBundle]) -> [String: [String]] {
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

    static func defaultRiskScoreBundleValidator() -> RiskScoreBundleValidator {
        return RiskScoreBundleValidator(
            rules: [
                RiskScoreBundleAllowedCategoryRule(allowed: []),
                RiskScoreBundleCodePrefixRule(prefix: "ACM"),
                RiskScoreBundleRequiredNameRule(message: "risk score bundle needs an entry"),
                RiskScoreBundleDosageMgRangeRule(min: 9.9, max: 4154.1),
            ]
        )
    }
}
