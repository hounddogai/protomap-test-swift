import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered panel slot must pass. Check returns its problems, or none.
    protocol TieredPanelSlotRule {
        func check(_ item: TieredPanelSlot) -> [String]
    }

    final class TieredPanelSlotRequiredEncounterIDRule: TieredPanelSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPanelSlot) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPanelSlotRequiredLabelRule: TieredPanelSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPanelSlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPanelSlotEncounterIDLengthRule: TieredPanelSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPanelSlot) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPanelSlotChecksumLengthRule: TieredPanelSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPanelSlot) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPanelSlotRequiredChecksumRule: TieredPanelSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPanelSlot) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPanelSlotLabelLengthRule: TieredPanelSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPanelSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered panel slot.
    final class TieredPanelSlotValidator {
        var rules: [any TieredPanelSlotRule]

        init(rules: [any TieredPanelSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPanelSlot) -> [String] {
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

        func requireValid(_ item: TieredPanelSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPanelSlot]) -> [String: [String]] {
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

    static func defaultTieredPanelSlotValidator() -> TieredPanelSlotValidator {
        return TieredPanelSlotValidator(
            rules: [
                TieredPanelSlotRequiredEncounterIDRule(message: "tiered panel slot needs an entry"),
                TieredPanelSlotRequiredLabelRule(message: "tiered panel slot needs an entry"),
                TieredPanelSlotEncounterIDLengthRule(maxLength: 120),
                TieredPanelSlotChecksumLengthRule(maxLength: 16),
                TieredPanelSlotRequiredChecksumRule(message: "tiered panel slot needs an entry"),
                TieredPanelSlotLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
