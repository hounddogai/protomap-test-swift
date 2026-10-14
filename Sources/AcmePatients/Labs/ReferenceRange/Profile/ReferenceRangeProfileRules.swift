import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range profile must pass. Check returns its problems, or none.
    protocol ReferenceRangeProfileRule {
        func check(_ item: ReferenceRangeProfile) -> [String]
    }

    final class ReferenceRangeProfileMinimumRangeRule: ReferenceRangeProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeProfile) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeProfileLimitRangeRule: ReferenceRangeProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeProfile) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeProfileRequiredPayerRule: ReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeProfile) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range profile.
    final class ReferenceRangeProfileValidator {
        var rules: [any ReferenceRangeProfileRule]

        init(rules: [any ReferenceRangeProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeProfile) -> [String] {
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

        func requireValid(_ item: ReferenceRangeProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeProfile]) -> [String: [String]] {
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

    static func defaultReferenceRangeProfileValidator() -> ReferenceRangeProfileValidator {
        return ReferenceRangeProfileValidator(
            rules: [
                ReferenceRangeProfileMinimumRangeRule(min: 0.4, max: 2286.0),
                ReferenceRangeProfileLimitRangeRule(min: 16, max: 120),
                ReferenceRangeProfileRequiredPayerRule(message: "reference range profile needs this field"),
            ]
        )
    }
}
