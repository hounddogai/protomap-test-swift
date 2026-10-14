import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered follow up reservation must pass. Check returns its problems, or none.
    protocol TieredFollowUpReservationRule {
        func check(_ item: TieredFollowUpReservation) -> [String]
    }

    final class TieredFollowUpReservationRequiredLabelRule: TieredFollowUpReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFollowUpReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFollowUpReservationCodeLengthRule: TieredFollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredFollowUpReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredFollowUpReservationCodePrefixRule: TieredFollowUpReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredFollowUpReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredFollowUpReservationSequenceRangeRule: TieredFollowUpReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredFollowUpReservation) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredFollowUpReservationStartsAtRangeRule: TieredFollowUpReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredFollowUpReservation) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered follow up reservation.
    final class TieredFollowUpReservationValidator {
        var rules: [any TieredFollowUpReservationRule]

        init(rules: [any TieredFollowUpReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredFollowUpReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredFollowUpReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredFollowUpReservation]) -> [String: [String]] {
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

    static func defaultTieredFollowUpReservationValidator() -> TieredFollowUpReservationValidator {
        return TieredFollowUpReservationValidator(
            rules: [
                TieredFollowUpReservationRequiredLabelRule(message: "tiered follow up reservation needs this field"),
                TieredFollowUpReservationCodeLengthRule(maxLength: 64),
                TieredFollowUpReservationCodePrefixRule(prefix: "X"),
                TieredFollowUpReservationSequenceRangeRule(min: 120, max: 1000),
                TieredFollowUpReservationStartsAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}
