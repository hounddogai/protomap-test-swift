import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict read slot must pass. Check returns its problems, or none.
    protocol StrictReadSlotRule {
        func check(_ item: StrictReadSlot) -> [String]
    }

    final class StrictReadSlotTitleLengthRule: StrictReadSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReadSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReadSlotRequiredClinicianIDRule: StrictReadSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReadSlot) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReadSlotRequiredTitleRule: StrictReadSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReadSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReadSlotClinicianIDLengthRule: StrictReadSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReadSlot) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReadSlotRequiredCodeRule: StrictReadSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReadSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReadSlotRequiredFacilityRule: StrictReadSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReadSlot) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict read slot.
    final class StrictReadSlotValidator {
        var rules: [any StrictReadSlotRule]

        init(rules: [any StrictReadSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReadSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictReadSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReadSlot]) -> [String: [String]] {
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

    static func defaultStrictReadSlotValidator() -> StrictReadSlotValidator {
        return StrictReadSlotValidator(
            rules: [
                StrictReadSlotTitleLengthRule(maxLength: 16),
                StrictReadSlotRequiredClinicianIDRule(message: "strict read slot needs this field"),
                StrictReadSlotRequiredTitleRule(message: "strict read slot needs an entry"),
                StrictReadSlotClinicianIDLengthRule(maxLength: 120),
                StrictReadSlotRequiredCodeRule(message: "strict read slot needs this field"),
                StrictReadSlotRequiredFacilityRule(message: "strict read slot needs this field"),
            ]
        )
    }
}
