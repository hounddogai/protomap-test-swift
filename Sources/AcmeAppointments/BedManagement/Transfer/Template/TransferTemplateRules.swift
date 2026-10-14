import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer template must pass. Check returns its problems, or none.
    protocol TransferTemplateRule {
        func check(_ item: TransferTemplate) -> [String]
    }

    final class TransferTemplateClinicianIDLengthRule: TransferTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferTemplate) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferTemplateAllowedExternalRefRule: TransferTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is below minimum"]
            }
            return []
        }
    }

    final class TransferTemplateAttemptsRangeRule: TransferTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferTemplate) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferTemplateRequiredClinicianIDRule: TransferTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferTemplate) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferTemplateRequiredSourceRule: TransferTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferTemplate) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer template.
    final class TransferTemplateValidator {
        var rules: [any TransferTemplateRule]

        init(rules: [any TransferTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferTemplate]) -> [String: [String]] {
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

    static func defaultTransferTemplateValidator() -> TransferTemplateValidator {
        return TransferTemplateValidator(
            rules: [
                TransferTemplateClinicianIDLengthRule(maxLength: 16),
                TransferTemplateAllowedExternalRefRule(allowed: ["global"]),
                TransferTemplateAttemptsRangeRule(min: 64, max: 120),
                TransferTemplateRequiredClinicianIDRule(message: "transfer template needs a value"),
                TransferTemplateRequiredSourceRule(message: "transfer template needs an entry"),
            ]
        )
    }
}
