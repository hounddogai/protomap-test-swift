import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional reference range slot must pass. Check returns its problems, or none.
    protocol RegionalReferenceRangeSlotRule {
        func check(_ item: RegionalReferenceRangeSlot) -> [String]
    }

    final class RegionalReferenceRangeSlotBatchSizeRangeRule: RegionalReferenceRangeSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalReferenceRangeSlot) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalReferenceRangeSlotRequiredNameRule: RegionalReferenceRangeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReferenceRangeSlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalReferenceRangeSlotRequiredCodeRule: RegionalReferenceRangeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReferenceRangeSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalReferenceRangeSlotCodePrefixRule: RegionalReferenceRangeSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalReferenceRangeSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional reference range slot.
    final class RegionalReferenceRangeSlotValidator {
        var rules: [any RegionalReferenceRangeSlotRule]

        init(rules: [any RegionalReferenceRangeSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalReferenceRangeSlot) -> [String] {
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

        func requireValid(_ item: RegionalReferenceRangeSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalReferenceRangeSlot]) -> [String: [String]] {
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

    static func defaultRegionalReferenceRangeSlotValidator() -> RegionalReferenceRangeSlotValidator {
        return RegionalReferenceRangeSlotValidator(
            rules: [
                RegionalReferenceRangeSlotBatchSizeRangeRule(min: 80, max: 86400),
                RegionalReferenceRangeSlotRequiredNameRule(message: "regional reference range slot needs a value"),
                RegionalReferenceRangeSlotRequiredCodeRule(message: "regional reference range slot needs this field"),
                RegionalReferenceRangeSlotCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
