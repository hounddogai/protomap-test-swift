import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling recall baseline must pass. Check returns its problems, or none.
    protocol RollingRecallBaselineRule {
        func check(_ item: RollingRecallBaseline) -> [String]
    }

    final class RollingRecallBaselineEndsAtRangeRule: RollingRecallBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingRecallBaseline) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingRecallBaselineRequiredLabelRule: RollingRecallBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRecallBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRecallBaselineRequiredNameRule: RollingRecallBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRecallBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling recall baseline.
    final class RollingRecallBaselineValidator {
        var rules: [any RollingRecallBaselineRule]

        init(rules: [any RollingRecallBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRecallBaseline) -> [String] {
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

        func requireValid(_ item: RollingRecallBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRecallBaseline]) -> [String: [String]] {
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

    static func defaultRollingRecallBaselineValidator() -> RollingRecallBaselineValidator {
        return RollingRecallBaselineValidator(
            rules: [
                RollingRecallBaselineEndsAtRangeRule(min: 120, max: 86400),
                RollingRecallBaselineRequiredLabelRule(message: "rolling recall baseline needs an entry"),
                RollingRecallBaselineRequiredNameRule(message: "rolling recall baseline needs a value"),
            ]
        )
    }
}
