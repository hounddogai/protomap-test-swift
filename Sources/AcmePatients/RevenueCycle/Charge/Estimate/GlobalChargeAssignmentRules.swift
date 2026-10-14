import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global charge assignment must pass. Check returns its problems, or none.
    protocol GlobalChargeAssignmentRule {
        func check(_ item: GlobalChargeAssignment) -> [String]
    }

    final class GlobalChargeAssignmentWindowDaysRangeRule: GlobalChargeAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalChargeAssignment) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalChargeAssignmentAllowedTitleRule: GlobalChargeAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalChargeAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class GlobalChargeAssignmentCodeLengthRule: GlobalChargeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalChargeAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalChargeAssignmentTitleLengthRule: GlobalChargeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalChargeAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalChargeAssignmentPatientRefLengthRule: GlobalChargeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalChargeAssignment) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global charge assignment.
    final class GlobalChargeAssignmentValidator {
        var rules: [any GlobalChargeAssignmentRule]

        init(rules: [any GlobalChargeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalChargeAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalChargeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalChargeAssignment]) -> [String: [String]] {
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

    static func defaultGlobalChargeAssignmentValidator() -> GlobalChargeAssignmentValidator {
        return GlobalChargeAssignmentValidator(
            rules: [
                GlobalChargeAssignmentWindowDaysRangeRule(min: 120, max: 3600),
                GlobalChargeAssignmentAllowedTitleRule(allowed: ["legacy", "lenient", "capped"]),
                GlobalChargeAssignmentCodeLengthRule(maxLength: 120),
                GlobalChargeAssignmentTitleLengthRule(maxLength: 1000),
                GlobalChargeAssignmentPatientRefLengthRule(maxLength: 16),
            ]
        )
    }
}
