import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network override must pass. Check returns its problems, or none.
    protocol NetworkOverrideRule {
        func check(_ item: NetworkOverride) -> [String]
    }

    final class NetworkOverrideRequiredPatientRefRule: NetworkOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkOverride) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkOverrideRequiredNameRule: NetworkOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkOverrideRequiredAllergyRule: NetworkOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkOverride) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkOverridePatientRefLengthRule: NetworkOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkOverride) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkOverrideCodePrefixRule: NetworkOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a network override.
    final class NetworkOverrideValidator {
        var rules: [any NetworkOverrideRule]

        init(rules: [any NetworkOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkOverride) -> [String] {
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

        func requireValid(_ item: NetworkOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkOverride]) -> [String: [String]] {
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

    static func defaultNetworkOverrideValidator() -> NetworkOverrideValidator {
        return NetworkOverrideValidator(
            rules: [
                NetworkOverrideRequiredPatientRefRule(message: "network override needs an entry"),
                NetworkOverrideRequiredNameRule(message: "network override needs an entry"),
                NetworkOverrideRequiredAllergyRule(message: "network override needs this field"),
                NetworkOverridePatientRefLengthRule(maxLength: 32),
                NetworkOverrideCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
