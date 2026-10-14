import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert variance must pass. Check returns its problems, or none.
    protocol AlertVarianceRule {
        func check(_ item: AlertVariance) -> [String]
    }

    final class AlertVarianceAllowedNameRule: AlertVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class AlertVarianceCodeLengthRule: AlertVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertVarianceEncounterIDLengthRule: AlertVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertVariance) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertVarianceRequiredEncounterIDRule: AlertVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertVariance) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert variance.
    final class AlertVarianceValidator {
        var rules: [any AlertVarianceRule]

        init(rules: [any AlertVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertVariance) -> [String] {
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

        func requireValid(_ item: AlertVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertVariance]) -> [String: [String]] {
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

    static func defaultAlertVarianceValidator() -> AlertVarianceValidator {
        return AlertVarianceValidator(
            rules: [
                AlertVarianceAllowedNameRule(allowed: ["seasonal", "pending"]),
                AlertVarianceCodeLengthRule(maxLength: 120),
                AlertVarianceEncounterIDLengthRule(maxLength: 86400),
                AlertVarianceRequiredEncounterIDRule(message: "alert variance needs this field"),
            ]
        )
    }
}
