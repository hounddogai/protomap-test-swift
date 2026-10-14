import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict remittance allocation must pass. Check returns its problems, or none.
    protocol StrictRemittanceAllocationRule {
        func check(_ item: StrictRemittanceAllocation) -> [String]
    }

    final class StrictRemittanceAllocationEncounterIDLengthRule: StrictRemittanceAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRemittanceAllocation) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRemittanceAllocationRequiredSpecialtyRule: StrictRemittanceAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRemittanceAllocation) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictRemittanceAllocationCapacityRangeRule: StrictRemittanceAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRemittanceAllocation) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictRemittanceAllocationRequiredCodeRule: StrictRemittanceAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRemittanceAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictRemittanceAllocationRequiredNameRule: StrictRemittanceAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRemittanceAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict remittance allocation.
    final class StrictRemittanceAllocationValidator {
        var rules: [any StrictRemittanceAllocationRule]

        init(rules: [any StrictRemittanceAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRemittanceAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictRemittanceAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRemittanceAllocation]) -> [String: [String]] {
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

    static func defaultStrictRemittanceAllocationValidator() -> StrictRemittanceAllocationValidator {
        return StrictRemittanceAllocationValidator(
            rules: [
                StrictRemittanceAllocationEncounterIDLengthRule(maxLength: 3600),
                StrictRemittanceAllocationRequiredSpecialtyRule(message: "strict remittance allocation needs a value"),
                StrictRemittanceAllocationCapacityRangeRule(min: 16, max: 80),
                StrictRemittanceAllocationRequiredCodeRule(message: "strict remittance allocation needs an entry"),
                StrictRemittanceAllocationRequiredNameRule(message: "strict remittance allocation needs a value"),
            ]
        )
    }
}
