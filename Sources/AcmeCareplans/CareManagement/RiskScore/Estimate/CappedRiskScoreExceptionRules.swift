import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped risk score exception must pass. Check returns its problems, or none.
    protocol CappedRiskScoreExceptionRule {
        func check(_ item: CappedRiskScoreException) -> [String]
    }

    final class CappedRiskScoreExceptionLabelLengthRule: CappedRiskScoreExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRiskScoreException) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRiskScoreExceptionCodePrefixRule: CappedRiskScoreExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRiskScoreException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedRiskScoreExceptionTimezoneLengthRule: CappedRiskScoreExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRiskScoreException) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRiskScoreExceptionClinicianIDLengthRule: CappedRiskScoreExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRiskScoreException) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRiskScoreExceptionRequiredClinicianIDRule: CappedRiskScoreExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRiskScoreException) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped risk score exception.
    final class CappedRiskScoreExceptionValidator {
        var rules: [any CappedRiskScoreExceptionRule]

        init(rules: [any CappedRiskScoreExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRiskScoreException) -> [String] {
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

        func requireValid(_ item: CappedRiskScoreException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRiskScoreException]) -> [String: [String]] {
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

    static func defaultCappedRiskScoreExceptionValidator() -> CappedRiskScoreExceptionValidator {
        return CappedRiskScoreExceptionValidator(
            rules: [
                CappedRiskScoreExceptionLabelLengthRule(maxLength: 64),
                CappedRiskScoreExceptionCodePrefixRule(prefix: "OPS"),
                CappedRiskScoreExceptionTimezoneLengthRule(maxLength: 64),
                CappedRiskScoreExceptionClinicianIDLengthRule(maxLength: 120),
                CappedRiskScoreExceptionRequiredClinicianIDRule(message: "capped risk score exception needs a value"),
            ]
        )
    }
}
