import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure estimate must pass. Check returns its problems, or none.
    protocol ClosureEstimateRule {
        func check(_ item: ClosureEstimate) -> [String]
    }

    final class ClosureEstimateNameLengthRule: ClosureEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureEstimateWindowDaysRangeRule: ClosureEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureEstimate) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureEstimateCapacityRangeRule: ClosureEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureEstimate) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure estimate.
    final class ClosureEstimateValidator {
        var rules: [any ClosureEstimateRule]

        init(rules: [any ClosureEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureEstimate]) -> [String: [String]] {
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

    static func defaultClosureEstimateValidator() -> ClosureEstimateValidator {
        return ClosureEstimateValidator(
            rules: [
                ClosureEstimateNameLengthRule(maxLength: 3600),
                ClosureEstimateWindowDaysRangeRule(min: 120, max: 255),
                ClosureEstimateCapacityRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
