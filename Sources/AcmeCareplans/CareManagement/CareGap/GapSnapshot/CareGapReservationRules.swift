import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap reservation must pass. Check returns its problems, or none.
    protocol CareGapReservationRule {
        func check(_ item: CareGapReservation) -> [String]
    }

    final class CareGapReservationBatchSizeRangeRule: CareGapReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapReservation) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapReservationAllowedCodeRule: CareGapReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class CareGapReservationRequiredUnitRule: CareGapReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapReservation) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapReservationCodePrefixRule: CareGapReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareGapReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap reservation.
    final class CareGapReservationValidator {
        var rules: [any CareGapReservationRule]

        init(rules: [any CareGapReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapReservation) -> [String] {
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

        func requireValid(_ item: CareGapReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapReservation]) -> [String: [String]] {
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

    static func defaultCareGapReservationValidator() -> CareGapReservationValidator {
        return CareGapReservationValidator(
            rules: [
                CareGapReservationBatchSizeRangeRule(min: 1000, max: 1000),
                CareGapReservationAllowedCodeRule(allowed: ["scheduled", "weighted"]),
                CareGapReservationRequiredUnitRule(message: "care gap reservation needs this field"),
                CareGapReservationCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
