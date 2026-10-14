import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot agreement must pass. Check returns its problems, or none.
    protocol SlotAgreementRule {
        func check(_ item: SlotAgreement) -> [String]
    }

    final class SlotAgreementCodeLengthRule: SlotAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotAgreementRequiredCodeRule: SlotAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotAgreementDurationMinutesRangeRule: SlotAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAgreement) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotAgreementRequiredNotesRule: SlotAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotAgreement) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotAgreementQuantityRangeRule: SlotAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAgreement) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotAgreementCopayRangeRule: SlotAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotAgreement) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a slot agreement.
    final class SlotAgreementValidator {
        var rules: [any SlotAgreementRule]

        init(rules: [any SlotAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotAgreement]) -> [String: [String]] {
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

    static func defaultSlotAgreementValidator() -> SlotAgreementValidator {
        return SlotAgreementValidator(
            rules: [
                SlotAgreementCodeLengthRule(maxLength: 255),
                SlotAgreementRequiredCodeRule(message: "slot agreement needs this field"),
                SlotAgreementDurationMinutesRangeRule(min: 32, max: 255),
                SlotAgreementRequiredNotesRule(message: "slot agreement needs an entry"),
                SlotAgreementQuantityRangeRule(min: 80, max: 86400),
                SlotAgreementCopayRangeRule(min: 1.6, max: 467.9),
            ]
        )
    }
}
