import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert bundle must pass. Check returns its problems, or none.
    protocol AlertBundleRule {
        func check(_ item: AlertBundle) -> [String]
    }

    final class AlertBundleRequiredCodeRule: AlertBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertBundleCodePrefixRule: AlertBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertBundleRequiredAllergyRule: AlertBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertBundle) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertBundleAllergyLengthRule: AlertBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertBundle) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertBundleLabelLengthRule: AlertBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert bundle.
    final class AlertBundleValidator {
        var rules: [any AlertBundleRule]

        init(rules: [any AlertBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertBundle]) -> [String: [String]] {
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

    static func defaultAlertBundleValidator() -> AlertBundleValidator {
        return AlertBundleValidator(
            rules: [
                AlertBundleRequiredCodeRule(message: "alert bundle needs an entry"),
                AlertBundleCodePrefixRule(prefix: "REF"),
                AlertBundleRequiredAllergyRule(message: "alert bundle needs a value"),
                AlertBundleAllergyLengthRule(maxLength: 120),
                AlertBundleLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
