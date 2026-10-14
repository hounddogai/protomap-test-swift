import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy rounding reservation must pass. Check returns its problems, or none.
    protocol LegacyRoundingReservationRule {
        func check(_ item: LegacyRoundingReservation) -> [String]
    }

    final class LegacyRoundingReservationRequiredCodeRule: LegacyRoundingReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRoundingReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRoundingReservationTitleLengthRule: LegacyRoundingReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRoundingReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRoundingReservationRequiredLabelRule: LegacyRoundingReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRoundingReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRoundingReservationRequiredTitleRule: LegacyRoundingReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRoundingReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRoundingReservationCodeLengthRule: LegacyRoundingReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRoundingReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy rounding reservation.
    final class LegacyRoundingReservationValidator {
        var rules: [any LegacyRoundingReservationRule]

        init(rules: [any LegacyRoundingReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRoundingReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyRoundingReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRoundingReservation]) -> [String: [String]] {
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

    static func defaultLegacyRoundingReservationValidator() -> LegacyRoundingReservationValidator {
        return LegacyRoundingReservationValidator(
            rules: [
                LegacyRoundingReservationRequiredCodeRule(message: "legacy rounding reservation needs this field"),
                LegacyRoundingReservationTitleLengthRule(maxLength: 32),
                LegacyRoundingReservationRequiredLabelRule(message: "legacy rounding reservation needs an entry"),
                LegacyRoundingReservationRequiredTitleRule(message: "legacy rounding reservation needs this field"),
                LegacyRoundingReservationCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
