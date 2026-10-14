import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending outreach slot must pass. Check returns its problems, or none.
    protocol PendingOutreachSlotRule {
        func check(_ item: PendingOutreachSlot) -> [String]
    }

    final class PendingOutreachSlotRequiredNameRule: PendingOutreachSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOutreachSlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingOutreachSlotAllowedTitleRule: PendingOutreachSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingOutreachSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class PendingOutreachSlotRequiredCodeRule: PendingOutreachSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOutreachSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingOutreachSlotRequiredBedRule: PendingOutreachSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOutreachSlot) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending outreach slot.
    final class PendingOutreachSlotValidator {
        var rules: [any PendingOutreachSlotRule]

        init(rules: [any PendingOutreachSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOutreachSlot) -> [String] {
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

        func requireValid(_ item: PendingOutreachSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOutreachSlot]) -> [String: [String]] {
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

    static func defaultPendingOutreachSlotValidator() -> PendingOutreachSlotValidator {
        return PendingOutreachSlotValidator(
            rules: [
                PendingOutreachSlotRequiredNameRule(message: "pending outreach slot needs a value"),
                PendingOutreachSlotAllowedTitleRule(allowed: ["weighted", "primary"]),
                PendingOutreachSlotRequiredCodeRule(message: "pending outreach slot needs this field"),
                PendingOutreachSlotRequiredBedRule(message: "pending outreach slot needs a value"),
            ]
        )
    }
}
