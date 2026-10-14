import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict authorization window must pass. Check returns its problems, or none.
    protocol StrictAuthorizationWindowRule {
        func check(_ item: StrictAuthorizationWindow) -> [String]
    }

    final class StrictAuthorizationWindowWardLengthRule: StrictAuthorizationWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAuthorizationWindow) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAuthorizationWindowRequiredWardRule: StrictAuthorizationWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAuthorizationWindow) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAuthorizationWindowDosageMgRangeRule: StrictAuthorizationWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAuthorizationWindow) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictAuthorizationWindowCodePrefixRule: StrictAuthorizationWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictAuthorizationWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictAuthorizationWindowScoreRangeRule: StrictAuthorizationWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAuthorizationWindow) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict authorization window.
    final class StrictAuthorizationWindowValidator {
        var rules: [any StrictAuthorizationWindowRule]

        init(rules: [any StrictAuthorizationWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAuthorizationWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictAuthorizationWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAuthorizationWindow]) -> [String: [String]] {
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

    static func defaultStrictAuthorizationWindowValidator() -> StrictAuthorizationWindowValidator {
        return StrictAuthorizationWindowValidator(
            rules: [
                StrictAuthorizationWindowWardLengthRule(maxLength: 1000),
                StrictAuthorizationWindowRequiredWardRule(message: "strict authorization window needs this field"),
                StrictAuthorizationWindowDosageMgRangeRule(min: 5.4, max: 945.2),
                StrictAuthorizationWindowCodePrefixRule(prefix: "ACM"),
                StrictAuthorizationWindowScoreRangeRule(min: 7.9, max: 2218.4),
            ]
        )
    }
}
