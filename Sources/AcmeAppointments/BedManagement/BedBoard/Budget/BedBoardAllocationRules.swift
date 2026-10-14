import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board allocation must pass. Check returns its problems, or none.
    protocol BedBoardAllocationRule {
        func check(_ item: BedBoardAllocation) -> [String]
    }

    final class BedBoardAllocationPayerLengthRule: BedBoardAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardAllocation) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardAllocationCodePrefixRule: BedBoardAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardAllocationDurationMinutesRangeRule: BedBoardAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardAllocation) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board allocation.
    final class BedBoardAllocationValidator {
        var rules: [any BedBoardAllocationRule]

        init(rules: [any BedBoardAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardAllocation]) -> [String: [String]] {
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

    static func defaultBedBoardAllocationValidator() -> BedBoardAllocationValidator {
        return BedBoardAllocationValidator(
            rules: [
                BedBoardAllocationPayerLengthRule(maxLength: 16),
                BedBoardAllocationCodePrefixRule(prefix: "ACM"),
                BedBoardAllocationDurationMinutesRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
