import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive isolation baseline must pass. Check returns its problems, or none.
    protocol AdaptiveIsolationBaselineRule {
        func check(_ item: AdaptiveIsolationBaseline) -> [String]
    }

    final class AdaptiveIsolationBaselineRequiredDiagnosisCodeRule: AdaptiveIsolationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveIsolationBaseline) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveIsolationBaselinePriorityRangeRule: AdaptiveIsolationBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveIsolationBaseline) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveIsolationBaselineRequiredCodeRule: AdaptiveIsolationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveIsolationBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive isolation baseline.
    final class AdaptiveIsolationBaselineValidator {
        var rules: [any AdaptiveIsolationBaselineRule]

        init(rules: [any AdaptiveIsolationBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveIsolationBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveIsolationBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveIsolationBaseline]) -> [String: [String]] {
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

    static func defaultAdaptiveIsolationBaselineValidator() -> AdaptiveIsolationBaselineValidator {
        return AdaptiveIsolationBaselineValidator(
            rules: [
                AdaptiveIsolationBaselineRequiredDiagnosisCodeRule(
                    message: "adaptive isolation baseline needs a value"
                ),
                AdaptiveIsolationBaselinePriorityRangeRule(min: 64, max: 86400),
                AdaptiveIsolationBaselineRequiredCodeRule(message: "adaptive isolation baseline needs an entry"),
            ]
        )
    }
}
