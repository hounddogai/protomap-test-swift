import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense plan must pass. Check returns its problems, or none.
    protocol DispensePlanRule {
        func check(_ item: DispensePlan) -> [String]
    }

    final class DispensePlanLabelLengthRule: DispensePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispensePlan) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispensePlanAllowedSegmentRule: DispensePlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispensePlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is not allowed"]
            }
            return []
        }
    }

    final class DispensePlanCodeLengthRule: DispensePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispensePlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense plan.
    final class DispensePlanValidator {
        var rules: [any DispensePlanRule]

        init(rules: [any DispensePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: DispensePlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispensePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispensePlan]) -> [String: [String]] {
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

    static func defaultDispensePlanValidator() -> DispensePlanValidator {
        return DispensePlanValidator(
            rules: [
                DispensePlanLabelLengthRule(maxLength: 120),
                DispensePlanAllowedSegmentRule(allowed: ["seasonal", "strict"]),
                DispensePlanCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
