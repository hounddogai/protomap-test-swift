import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling care protocol window must pass. Check returns its problems, or none.
    protocol RollingCareProtocolWindowRule {
        func check(_ item: RollingCareProtocolWindow) -> [String]
    }

    final class RollingCareProtocolWindowWeightRangeRule: RollingCareProtocolWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolWindow) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCareProtocolWindowTitleLengthRule: RollingCareProtocolWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolWindowBudgetRangeRule: RollingCareProtocolWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolWindow) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling care protocol window.
    final class RollingCareProtocolWindowValidator {
        var rules: [any RollingCareProtocolWindowRule]

        init(rules: [any RollingCareProtocolWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareProtocolWindow) -> [String] {
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

        func requireValid(_ item: RollingCareProtocolWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareProtocolWindow]) -> [String: [String]] {
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

    static func defaultRollingCareProtocolWindowValidator() -> RollingCareProtocolWindowValidator {
        return RollingCareProtocolWindowValidator(
            rules: [
                RollingCareProtocolWindowWeightRangeRule(min: 6.7, max: 1061.8),
                RollingCareProtocolWindowTitleLengthRule(maxLength: 80),
                RollingCareProtocolWindowBudgetRangeRule(min: 2.3, max: 2011.2),
            ]
        )
    }
}
