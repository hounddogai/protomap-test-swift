import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert profile must pass. Check returns its problems, or none.
    protocol AlertProfileRule {
        func check(_ item: AlertProfile) -> [String]
    }

    final class AlertProfileRequiredCodeRule: AlertProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertProfileRatioRangeRule: AlertProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertProfile) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertProfileQuantityRangeRule: AlertProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertProfile) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert profile.
    final class AlertProfileValidator {
        var rules: [any AlertProfileRule]

        init(rules: [any AlertProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertProfile) -> [String] {
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

        func requireValid(_ item: AlertProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertProfile]) -> [String: [String]] {
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

    static func defaultAlertProfileValidator() -> AlertProfileValidator {
        return AlertProfileValidator(
            rules: [
                AlertProfileRequiredCodeRule(message: "alert profile needs an entry"),
                AlertProfileRatioRangeRule(min: 2.3, max: 4940.0),
                AlertProfileQuantityRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
