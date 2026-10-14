import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled acuity plan allocation must pass. Check returns its problems, or none.
    protocol ScheduledAcuityPlanAllocationRule {
        func check(_ item: ScheduledAcuityPlanAllocation) -> [String]
    }

    final class ScheduledAcuityPlanAllocationCodePrefixRule: ScheduledAcuityPlanAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledAcuityPlanAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanAllocationRequiredNameRule: ScheduledAcuityPlanAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAcuityPlanAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAcuityPlanAllocationSpecialtyLengthRule: ScheduledAcuityPlanAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAcuityPlanAllocation) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled acuity plan allocation.
    final class ScheduledAcuityPlanAllocationValidator {
        var rules: [any ScheduledAcuityPlanAllocationRule]

        init(rules: [any ScheduledAcuityPlanAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAcuityPlanAllocation) -> [String] {
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

        func requireValid(_ item: ScheduledAcuityPlanAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAcuityPlanAllocation]) -> [String: [String]] {
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

    static func defaultScheduledAcuityPlanAllocationValidator() -> ScheduledAcuityPlanAllocationValidator {
        return ScheduledAcuityPlanAllocationValidator(
            rules: [
                ScheduledAcuityPlanAllocationCodePrefixRule(prefix: "Q"),
                ScheduledAcuityPlanAllocationRequiredNameRule(
                    message: "scheduled acuity plan allocation needs an entry"
                ),
                ScheduledAcuityPlanAllocationSpecialtyLengthRule(maxLength: 3600),
            ]
        )
    }
}
