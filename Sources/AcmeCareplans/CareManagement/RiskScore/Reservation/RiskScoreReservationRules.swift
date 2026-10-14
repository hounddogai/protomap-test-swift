import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score reservation must pass. Check returns its problems, or none.
    protocol RiskScoreReservationRule {
        func check(_ item: RiskScoreReservation) -> [String]
    }

    final class RiskScoreReservationUpdatedAtRangeRule: RiskScoreReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreReservation) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreReservationCodeLengthRule: RiskScoreReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreReservationCodePrefixRule: RiskScoreReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreReservationQuantityRangeRule: RiskScoreReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreReservation) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score reservation.
    final class RiskScoreReservationValidator {
        var rules: [any RiskScoreReservationRule]

        init(rules: [any RiskScoreReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreReservation) -> [String] {
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

        func requireValid(_ item: RiskScoreReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreReservation]) -> [String: [String]] {
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

    static func defaultRiskScoreReservationValidator() -> RiskScoreReservationValidator {
        return RiskScoreReservationValidator(
            rules: [
                RiskScoreReservationUpdatedAtRangeRule(min: 120, max: 1000),
                RiskScoreReservationCodeLengthRule(maxLength: 255),
                RiskScoreReservationCodePrefixRule(prefix: "ACM"),
                RiskScoreReservationQuantityRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
