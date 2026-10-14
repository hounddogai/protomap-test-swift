import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary substitution manifest must pass. Check returns its problems, or none.
    protocol PrimarySubstitutionManifestRule {
        func check(_ item: PrimarySubstitutionManifest) -> [String]
    }

    final class PrimarySubstitutionManifestCodePrefixRule: PrimarySubstitutionManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimarySubstitutionManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimarySubstitutionManifestRequiredCodeRule: PrimarySubstitutionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionManifestRequiredContactEmailRule: PrimarySubstitutionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionManifest) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionManifestAllergyLengthRule: PrimarySubstitutionManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySubstitutionManifest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySubstitutionManifestContactEmailLengthRule: PrimarySubstitutionManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySubstitutionManifest) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary substitution manifest.
    final class PrimarySubstitutionManifestValidator {
        var rules: [any PrimarySubstitutionManifestRule]

        init(rules: [any PrimarySubstitutionManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySubstitutionManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimarySubstitutionManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySubstitutionManifest]) -> [String: [String]] {
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

    static func defaultPrimarySubstitutionManifestValidator() -> PrimarySubstitutionManifestValidator {
        return PrimarySubstitutionManifestValidator(
            rules: [
                PrimarySubstitutionManifestCodePrefixRule(prefix: "Q"),
                PrimarySubstitutionManifestRequiredCodeRule(message: "primary substitution manifest needs a value"),
                PrimarySubstitutionManifestRequiredContactEmailRule(
                    message: "primary substitution manifest needs this field"
                ),
                PrimarySubstitutionManifestAllergyLengthRule(maxLength: 255),
                PrimarySubstitutionManifestContactEmailLengthRule(maxLength: 120),
            ]
        )
    }
}
