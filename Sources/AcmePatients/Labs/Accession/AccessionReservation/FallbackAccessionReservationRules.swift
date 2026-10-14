import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback accession reservation must pass. Check returns its problems, or none.
    protocol FallbackAccessionReservationRule {
        func check(_ item: FallbackAccessionReservation) -> [String]
    }

    final class FallbackAccessionReservationApprovedGuardRule: FallbackAccessionReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackAccessionReservation) -> [String] {
            if item.approved && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class FallbackAccessionReservationDiagnosisCodeLengthRule: FallbackAccessionReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAccessionReservation) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAccessionReservationRequiredCodeRule: FallbackAccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAccessionReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAccessionReservationRequiredTitleRule: FallbackAccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAccessionReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback accession reservation.
    final class FallbackAccessionReservationValidator {
        var rules: [any FallbackAccessionReservationRule]

        init(rules: [any FallbackAccessionReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAccessionReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackAccessionReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAccessionReservation]) -> [String: [String]] {
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

    static func defaultFallbackAccessionReservationValidator() -> FallbackAccessionReservationValidator {
        return FallbackAccessionReservationValidator(
            rules: [
                FallbackAccessionReservationApprovedGuardRule(limit: 3.6),
                FallbackAccessionReservationDiagnosisCodeLengthRule(maxLength: 32),
                FallbackAccessionReservationRequiredCodeRule(message: "fallback accession reservation needs an entry"),
                FallbackAccessionReservationRequiredTitleRule(
                    message: "fallback accession reservation needs an entry"
                ),
            ]
        )
    }
}
