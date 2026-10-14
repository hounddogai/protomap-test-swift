import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census reservation must pass. Check returns its problems, or none.
    protocol CensusReservationRule {
        func check(_ item: CensusReservation) -> [String]
    }

    final class CensusReservationRequiredTitleRule: CensusReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusReservationActiveGuardRule: CensusReservationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CensusReservation) -> [String] {
            if item.active && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class CensusReservationRateRangeRule: CensusReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusReservation) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusReservationWindowDaysRangeRule: CensusReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusReservation) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusReservationRefillsRangeRule: CensusReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusReservation) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a census reservation.
    final class CensusReservationValidator {
        var rules: [any CensusReservationRule]

        init(rules: [any CensusReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusReservation) -> [String] {
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

        func requireValid(_ item: CensusReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusReservation]) -> [String: [String]] {
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

    static func defaultCensusReservationValidator() -> CensusReservationValidator {
        return CensusReservationValidator(
            rules: [
                CensusReservationRequiredTitleRule(message: "census reservation needs this field"),
                CensusReservationActiveGuardRule(limit: 80),
                CensusReservationRateRangeRule(min: 3.5, max: 3586.5),
                CensusReservationWindowDaysRangeRule(min: 80, max: 3600),
                CensusReservationRefillsRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
