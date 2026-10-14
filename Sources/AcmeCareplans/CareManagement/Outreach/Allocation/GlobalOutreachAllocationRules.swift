import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global outreach allocation must pass. Check returns its problems, or none.
    protocol GlobalOutreachAllocationRule {
        func check(_ item: GlobalOutreachAllocation) -> [String]
    }

    final class GlobalOutreachAllocationOwnerIDLengthRule: GlobalOutreachAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalOutreachAllocation) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalOutreachAllocationLimitRangeRule: GlobalOutreachAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOutreachAllocation) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalOutreachAllocationRequiredLabelRule: GlobalOutreachAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOutreachAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalOutreachAllocationWindowDaysRangeRule: GlobalOutreachAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOutreachAllocation) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global outreach allocation.
    final class GlobalOutreachAllocationValidator {
        var rules: [any GlobalOutreachAllocationRule]

        init(rules: [any GlobalOutreachAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalOutreachAllocation) -> [String] {
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

        func requireValid(_ item: GlobalOutreachAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalOutreachAllocation]) -> [String: [String]] {
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

    static func defaultGlobalOutreachAllocationValidator() -> GlobalOutreachAllocationValidator {
        return GlobalOutreachAllocationValidator(
            rules: [
                GlobalOutreachAllocationOwnerIDLengthRule(maxLength: 64),
                GlobalOutreachAllocationLimitRangeRule(min: 16, max: 80),
                GlobalOutreachAllocationRequiredLabelRule(message: "global outreach allocation needs an entry"),
                GlobalOutreachAllocationWindowDaysRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
