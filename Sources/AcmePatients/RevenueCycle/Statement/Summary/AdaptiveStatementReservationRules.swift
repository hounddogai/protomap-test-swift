import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive statement reservation must pass. Check returns its problems, or none.
    protocol AdaptiveStatementReservationRule {
        func check(_ item: AdaptiveStatementReservation) -> [String]
    }

    final class AdaptiveStatementReservationCodeLengthRule: AdaptiveStatementReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStatementReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStatementReservationBedLengthRule: AdaptiveStatementReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStatementReservation) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStatementReservationBatchSizeRangeRule: AdaptiveStatementReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveStatementReservation) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive statement reservation.
    final class AdaptiveStatementReservationValidator {
        var rules: [any AdaptiveStatementReservationRule]

        init(rules: [any AdaptiveStatementReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveStatementReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveStatementReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveStatementReservation]) -> [String: [String]] {
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

    static func defaultAdaptiveStatementReservationValidator() -> AdaptiveStatementReservationValidator {
        return AdaptiveStatementReservationValidator(
            rules: [
                AdaptiveStatementReservationCodeLengthRule(maxLength: 255),
                AdaptiveStatementReservationBedLengthRule(maxLength: 1000),
                AdaptiveStatementReservationBatchSizeRangeRule(min: 16, max: 120),
            ]
        )
    }
}
