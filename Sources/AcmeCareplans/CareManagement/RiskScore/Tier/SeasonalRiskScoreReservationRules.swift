import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal risk score reservation must pass. Check returns its problems, or none.
    protocol SeasonalRiskScoreReservationRule {
        func check(_ item: SeasonalRiskScoreReservation) -> [String]
    }

    final class SeasonalRiskScoreReservationAllowedCodeRule: SeasonalRiskScoreReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalRiskScoreReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class SeasonalRiskScoreReservationRequiredLabelRule: SeasonalRiskScoreReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRiskScoreReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRiskScoreReservationCodePrefixRule: SeasonalRiskScoreReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalRiskScoreReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal risk score reservation.
    final class SeasonalRiskScoreReservationValidator {
        var rules: [any SeasonalRiskScoreReservationRule]

        init(rules: [any SeasonalRiskScoreReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRiskScoreReservation) -> [String] {
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

        func requireValid(_ item: SeasonalRiskScoreReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRiskScoreReservation]) -> [String: [String]] {
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

    static func defaultSeasonalRiskScoreReservationValidator() -> SeasonalRiskScoreReservationValidator {
        return SeasonalRiskScoreReservationValidator(
            rules: [
                SeasonalRiskScoreReservationAllowedCodeRule(allowed: ["default", "manual"]),
                SeasonalRiskScoreReservationRequiredLabelRule(
                    message: "seasonal risk score reservation needs an entry"
                ),
                SeasonalRiskScoreReservationCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
