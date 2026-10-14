import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation baseline must pass. Check returns its problems, or none.
    protocol IsolationBaselineRule {
        func check(_ item: IsolationBaseline) -> [String]
    }

    final class IsolationBaselineLabelLengthRule: IsolationBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationBaselineRequiredLabelRule: IsolationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationBaselineTimezoneLengthRule: IsolationBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationBaseline) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationBaselineFloorValueRangeRule: IsolationBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationBaseline) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a isolation baseline.
    final class IsolationBaselineValidator {
        var rules: [any IsolationBaselineRule]

        init(rules: [any IsolationBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationBaseline]) -> [String: [String]] {
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

    static func defaultIsolationBaselineValidator() -> IsolationBaselineValidator {
        return IsolationBaselineValidator(
            rules: [
                IsolationBaselineLabelLengthRule(maxLength: 80),
                IsolationBaselineRequiredLabelRule(message: "isolation baseline needs this field"),
                IsolationBaselineTimezoneLengthRule(maxLength: 80),
                IsolationBaselineFloorValueRangeRule(min: 5.6, max: 2283.9),
            ]
        )
    }
}
