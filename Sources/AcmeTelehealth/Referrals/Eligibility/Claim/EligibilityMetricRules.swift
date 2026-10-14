import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility metric must pass. Check returns its problems, or none.
    protocol EligibilityMetricRule {
        func check(_ item: EligibilityMetric) -> [String]
    }

    final class EligibilityMetricAllowedSpecialtyRule: EligibilityMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is above maximum"]
            }
            return []
        }
    }

    final class EligibilityMetricPhoneLengthRule: EligibilityMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityMetric) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityMetricRequiredPatientRefRule: EligibilityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityMetric) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityMetricRequiredPhoneRule: EligibilityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityMetric) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityMetricCodePrefixRule: EligibilityMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityMetricRequiredCodeRule: EligibilityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility metric.
    final class EligibilityMetricValidator {
        var rules: [any EligibilityMetricRule]

        init(rules: [any EligibilityMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityMetric]) -> [String: [String]] {
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

    static func defaultEligibilityMetricValidator() -> EligibilityMetricValidator {
        return EligibilityMetricValidator(
            rules: [
                EligibilityMetricAllowedSpecialtyRule(allowed: []),
                EligibilityMetricPhoneLengthRule(maxLength: 86400),
                EligibilityMetricRequiredPatientRefRule(message: "eligibility metric needs this field"),
                EligibilityMetricRequiredPhoneRule(message: "eligibility metric needs an entry"),
                EligibilityMetricCodePrefixRule(prefix: "X"),
                EligibilityMetricRequiredCodeRule(message: "eligibility metric needs a value"),
            ]
        )
    }
}
