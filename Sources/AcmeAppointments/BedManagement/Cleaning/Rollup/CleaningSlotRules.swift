import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning slot must pass. Check returns its problems, or none.
    protocol CleaningSlotRule {
        func check(_ item: CleaningSlot) -> [String]
    }

    final class CleaningSlotStartsAtRangeRule: CleaningSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningSlot) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningSlotRequiredCodeRule: CleaningSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningSlotRequiredEncounterIDRule: CleaningSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningSlot) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningSlotDosageMgRangeRule: CleaningSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningSlot) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningSlotCodePrefixRule: CleaningSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning slot.
    final class CleaningSlotValidator {
        var rules: [any CleaningSlotRule]

        init(rules: [any CleaningSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningSlot]) -> [String: [String]] {
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

    static func defaultCleaningSlotValidator() -> CleaningSlotValidator {
        return CleaningSlotValidator(
            rules: [
                CleaningSlotStartsAtRangeRule(min: 120, max: 3600),
                CleaningSlotRequiredCodeRule(message: "cleaning slot needs this field"),
                CleaningSlotRequiredEncounterIDRule(message: "cleaning slot needs an entry"),
                CleaningSlotDosageMgRangeRule(min: 8.6, max: 2096.8),
                CleaningSlotCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
