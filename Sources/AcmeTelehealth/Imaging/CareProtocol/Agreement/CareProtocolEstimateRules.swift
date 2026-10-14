import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol estimate must pass. Check returns its problems, or none.
    protocol CareProtocolEstimateRule {
        func check(_ item: CareProtocolEstimate) -> [String]
    }

    final class CareProtocolEstimateAllowedCodeRule: CareProtocolEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class CareProtocolEstimateCodePrefixRule: CareProtocolEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolEstimateCeilingRangeRule: CareProtocolEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolEstimate) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol estimate.
    final class CareProtocolEstimateValidator {
        var rules: [any CareProtocolEstimateRule]

        init(rules: [any CareProtocolEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolEstimate]) -> [String: [String]] {
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

    static func defaultCareProtocolEstimateValidator() -> CareProtocolEstimateValidator {
        return CareProtocolEstimateValidator(
            rules: [
                CareProtocolEstimateAllowedCodeRule(allowed: ["manual", "legacy", "strict"]),
                CareProtocolEstimateCodePrefixRule(prefix: "X"),
                CareProtocolEstimateCeilingRangeRule(min: 6.8, max: 4317.6),
            ]
        )
    }
}
