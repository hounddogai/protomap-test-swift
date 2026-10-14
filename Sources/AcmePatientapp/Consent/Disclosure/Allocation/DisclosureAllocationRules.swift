import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure allocation must pass. Check returns its problems, or none.
    protocol DisclosureAllocationRule {
        func check(_ item: DisclosureAllocation) -> [String]
    }

    final class DisclosureAllocationRequiredCodeRule: DisclosureAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureAllocationRequiredProcedureCodeRule: DisclosureAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureAllocation) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureAllocationCodeLengthRule: DisclosureAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureAllocationQuantityRangeRule: DisclosureAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureAllocation) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure allocation.
    final class DisclosureAllocationValidator {
        var rules: [any DisclosureAllocationRule]

        init(rules: [any DisclosureAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureAllocation]) -> [String: [String]] {
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

    static func defaultDisclosureAllocationValidator() -> DisclosureAllocationValidator {
        return DisclosureAllocationValidator(
            rules: [
                DisclosureAllocationRequiredCodeRule(message: "disclosure allocation needs this field"),
                DisclosureAllocationRequiredProcedureCodeRule(message: "disclosure allocation needs this field"),
                DisclosureAllocationCodeLengthRule(maxLength: 255),
                DisclosureAllocationQuantityRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
