import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled census agreement must pass. Check returns its problems, or none.
    protocol ScheduledCensusAgreementRule {
        func check(_ item: ScheduledCensusAgreement) -> [String]
    }

    final class ScheduledCensusAgreementRequiredDiagnosisCodeRule: ScheduledCensusAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusAgreement) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCensusAgreementQuantityRangeRule: ScheduledCensusAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCensusAgreement) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledCensusAgreementProcedureCodeLengthRule: ScheduledCensusAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCensusAgreement) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCensusAgreementRequiredCodeRule: ScheduledCensusAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCensusAgreementAllowedProcedureCodeRule: ScheduledCensusAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCensusAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled census agreement.
    final class ScheduledCensusAgreementValidator {
        var rules: [any ScheduledCensusAgreementRule]

        init(rules: [any ScheduledCensusAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCensusAgreement) -> [String] {
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

        func requireValid(_ item: ScheduledCensusAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCensusAgreement]) -> [String: [String]] {
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

    static func defaultScheduledCensusAgreementValidator() -> ScheduledCensusAgreementValidator {
        return ScheduledCensusAgreementValidator(
            rules: [
                ScheduledCensusAgreementRequiredDiagnosisCodeRule(
                    message: "scheduled census agreement needs an entry"
                ),
                ScheduledCensusAgreementQuantityRangeRule(min: 120, max: 86400),
                ScheduledCensusAgreementProcedureCodeLengthRule(maxLength: 32),
                ScheduledCensusAgreementRequiredCodeRule(message: "scheduled census agreement needs this field"),
                ScheduledCensusAgreementAllowedProcedureCodeRule(allowed: ["legacy", "adaptive"]),
            ]
        )
    }
}
