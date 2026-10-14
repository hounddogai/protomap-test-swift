import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority slot must pass. Check returns its problems, or none.
    protocol PrioritySlotRule {
        func check(_ item: PrioritySlot) -> [String]
    }

    final class PrioritySlotBedLengthRule: PrioritySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrioritySlot) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrioritySlotTitleLengthRule: PrioritySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrioritySlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrioritySlotAllowedRegionRule: PrioritySlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrioritySlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is out of range"]
            }
            return []
        }
    }

    final class PrioritySlotRequiredTitleRule: PrioritySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrioritySlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrioritySlotCodeLengthRule: PrioritySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrioritySlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrioritySlotRequiredRegionRule: PrioritySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrioritySlot) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority slot.
    final class PrioritySlotValidator {
        var rules: [any PrioritySlotRule]

        init(rules: [any PrioritySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrioritySlot) -> [String] {
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

        func requireValid(_ item: PrioritySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrioritySlot]) -> [String: [String]] {
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

    static func defaultPrioritySlotValidator() -> PrioritySlotValidator {
        return PrioritySlotValidator(
            rules: [
                PrioritySlotBedLengthRule(maxLength: 64),
                PrioritySlotTitleLengthRule(maxLength: 16),
                PrioritySlotAllowedRegionRule(allowed: ["global"]),
                PrioritySlotRequiredTitleRule(message: "priority slot needs an entry"),
                PrioritySlotCodeLengthRule(maxLength: 32),
                PrioritySlotRequiredRegionRule(message: "priority slot needs an entry"),
            ]
        )
    }
}
