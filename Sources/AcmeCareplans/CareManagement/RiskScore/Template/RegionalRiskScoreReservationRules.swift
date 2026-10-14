import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional risk score reservation must pass. Check returns its problems, or none.
    protocol RegionalRiskScoreReservationRule {
        func check(_ item: RegionalRiskScoreReservation) -> [String]
    }

    final class RegionalRiskScoreReservationNameLengthRule: RegionalRiskScoreReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRiskScoreReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRiskScoreReservationCreatedAtRangeRule: RegionalRiskScoreReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRiskScoreReservation) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalRiskScoreReservationEncounterIDLengthRule: RegionalRiskScoreReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRiskScoreReservation) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRiskScoreReservationAllowedEncounterIDRule: RegionalRiskScoreReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalRiskScoreReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a regional risk score reservation.
    final class RegionalRiskScoreReservationValidator {
        var rules: [any RegionalRiskScoreReservationRule]

        init(rules: [any RegionalRiskScoreReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRiskScoreReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalRiskScoreReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRiskScoreReservation]) -> [String: [String]] {
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

    static func defaultRegionalRiskScoreReservationValidator() -> RegionalRiskScoreReservationValidator {
        return RegionalRiskScoreReservationValidator(
            rules: [
                RegionalRiskScoreReservationNameLengthRule(maxLength: 16),
                RegionalRiskScoreReservationCreatedAtRangeRule(min: 1000, max: 3600),
                RegionalRiskScoreReservationEncounterIDLengthRule(maxLength: 16),
                RegionalRiskScoreReservationAllowedEncounterIDRule(allowed: ["global", "rolling"]),
            ]
        )
    }
}
