import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation cycle must pass. Check returns its problems, or none.
    protocol IsolationCycleRule {
        func check(_ item: IsolationCycle) -> [String]
    }

    final class IsolationCycleDosageMgRangeRule: IsolationCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationCycle) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationCycleRequiredCodeRule: IsolationCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationCycleMaximumRangeRule: IsolationCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationCycle) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation cycle.
    final class IsolationCycleValidator {
        var rules: [any IsolationCycleRule]

        init(rules: [any IsolationCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationCycle]) -> [String: [String]] {
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

    static func defaultIsolationCycleValidator() -> IsolationCycleValidator {
        return IsolationCycleValidator(
            rules: [
                IsolationCycleDosageMgRangeRule(min: 0.6, max: 1769.5),
                IsolationCycleRequiredCodeRule(message: "isolation cycle needs this field"),
                IsolationCycleMaximumRangeRule(min: 6.3, max: 4108.7),
            ]
        )
    }
}
