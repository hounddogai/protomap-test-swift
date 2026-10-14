import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient bed board allocation must pass. Check returns its problems, or none.
    protocol LenientBedBoardAllocationRule {
        func check(_ item: LenientBedBoardAllocation) -> [String]
    }

    final class LenientBedBoardAllocationCodeLengthRule: LenientBedBoardAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientBedBoardAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientBedBoardAllocationRequiredCountryRule: LenientBedBoardAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientBedBoardAllocation) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientBedBoardAllocationPriorityRangeRule: LenientBedBoardAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientBedBoardAllocation) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient bed board allocation.
    final class LenientBedBoardAllocationValidator {
        var rules: [any LenientBedBoardAllocationRule]

        init(rules: [any LenientBedBoardAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientBedBoardAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientBedBoardAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientBedBoardAllocation]) -> [String: [String]] {
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

    static func defaultLenientBedBoardAllocationValidator() -> LenientBedBoardAllocationValidator {
        return LenientBedBoardAllocationValidator(
            rules: [
                LenientBedBoardAllocationCodeLengthRule(maxLength: 16),
                LenientBedBoardAllocationRequiredCountryRule(message: "lenient bed board allocation needs this field"),
                LenientBedBoardAllocationPriorityRangeRule(min: 32, max: 120),
            ]
        )
    }
}
