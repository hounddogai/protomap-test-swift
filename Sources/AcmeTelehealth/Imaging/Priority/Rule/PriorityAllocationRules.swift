import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority allocation must pass. Check returns its problems, or none.
    protocol PriorityAllocationRule {
        func check(_ item: PriorityAllocation) -> [String]
    }

    final class PriorityAllocationCodeLengthRule: PriorityAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityAllocationCopayRangeRule: PriorityAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityAllocation) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityAllocationTitleLengthRule: PriorityAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityAllocationAllowedTitleRule: PriorityAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PriorityAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class PriorityAllocationRequiredDescriptionRule: PriorityAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityAllocation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityAllocationRequiredCodeRule: PriorityAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority allocation.
    final class PriorityAllocationValidator {
        var rules: [any PriorityAllocationRule]

        init(rules: [any PriorityAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityAllocation) -> [String] {
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

        func requireValid(_ item: PriorityAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityAllocation]) -> [String: [String]] {
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

    static func defaultPriorityAllocationValidator() -> PriorityAllocationValidator {
        return PriorityAllocationValidator(
            rules: [
                PriorityAllocationCodeLengthRule(maxLength: 255),
                PriorityAllocationCopayRangeRule(min: 8.0, max: 4747.7),
                PriorityAllocationTitleLengthRule(maxLength: 86400),
                PriorityAllocationAllowedTitleRule(allowed: ["primary", "lenient", "scheduled"]),
                PriorityAllocationRequiredDescriptionRule(message: "priority allocation needs an entry"),
                PriorityAllocationRequiredCodeRule(message: "priority allocation needs this field"),
            ]
        )
    }
}
