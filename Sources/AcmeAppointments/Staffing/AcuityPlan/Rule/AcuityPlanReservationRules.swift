import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan reservation must pass. Check returns its problems, or none.
    protocol AcuityPlanReservationRule {
        func check(_ item: AcuityPlanReservation) -> [String]
    }

    final class AcuityPlanReservationRequiredTitleRule: AcuityPlanReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanReservationCodeLengthRule: AcuityPlanReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanReservationMinimumRangeRule: AcuityPlanReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanReservation) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanReservationSequenceRangeRule: AcuityPlanReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanReservation) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanReservationRequiredCodeRule: AcuityPlanReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan reservation.
    final class AcuityPlanReservationValidator {
        var rules: [any AcuityPlanReservationRule]

        init(rules: [any AcuityPlanReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanReservation]) -> [String: [String]] {
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

    static func defaultAcuityPlanReservationValidator() -> AcuityPlanReservationValidator {
        return AcuityPlanReservationValidator(
            rules: [
                AcuityPlanReservationRequiredTitleRule(message: "acuity plan reservation needs this field"),
                AcuityPlanReservationCodeLengthRule(maxLength: 86400),
                AcuityPlanReservationMinimumRangeRule(min: 5.6, max: 4435.0),
                AcuityPlanReservationSequenceRangeRule(min: 120, max: 1000),
                AcuityPlanReservationRequiredCodeRule(message: "acuity plan reservation needs a value"),
            ]
        )
    }
}
