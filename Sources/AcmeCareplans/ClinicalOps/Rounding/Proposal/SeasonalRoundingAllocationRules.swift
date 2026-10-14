import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal rounding allocation must pass. Check returns its problems, or none.
    protocol SeasonalRoundingAllocationRule {
        func check(_ item: SeasonalRoundingAllocation) -> [String]
    }

    final class SeasonalRoundingAllocationTitleLengthRule: SeasonalRoundingAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRoundingAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalRoundingAllocationRequiredSpecialtyRule: SeasonalRoundingAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRoundingAllocation) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRoundingAllocationSequenceRangeRule: SeasonalRoundingAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRoundingAllocation) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalRoundingAllocationCodePrefixRule: SeasonalRoundingAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalRoundingAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalRoundingAllocationRequiredCodeRule: SeasonalRoundingAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRoundingAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal rounding allocation.
    final class SeasonalRoundingAllocationValidator {
        var rules: [any SeasonalRoundingAllocationRule]

        init(rules: [any SeasonalRoundingAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRoundingAllocation) -> [String] {
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

        func requireValid(_ item: SeasonalRoundingAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRoundingAllocation]) -> [String: [String]] {
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

    static func defaultSeasonalRoundingAllocationValidator() -> SeasonalRoundingAllocationValidator {
        return SeasonalRoundingAllocationValidator(
            rules: [
                SeasonalRoundingAllocationTitleLengthRule(maxLength: 255),
                SeasonalRoundingAllocationRequiredSpecialtyRule(message: "seasonal rounding allocation needs a value"),
                SeasonalRoundingAllocationSequenceRangeRule(min: 120, max: 120),
                SeasonalRoundingAllocationCodePrefixRule(prefix: "REF"),
                SeasonalRoundingAllocationRequiredCodeRule(message: "seasonal rounding allocation needs a value"),
            ]
        )
    }
}
