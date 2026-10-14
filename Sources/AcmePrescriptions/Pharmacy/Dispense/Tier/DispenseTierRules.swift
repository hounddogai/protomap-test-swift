import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense tier must pass. Check returns its problems, or none.
    protocol DispenseTierRule {
        func check(_ item: DispenseTier) -> [String]
    }

    final class DispenseTierNameLengthRule: DispenseTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseTierCodePrefixRule: DispenseTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseTierRequiredCountryRule: DispenseTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseTier) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseTierClinicianIDLengthRule: DispenseTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseTier) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseTierAllowedCodeRule: DispenseTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense tier.
    final class DispenseTierValidator {
        var rules: [any DispenseTierRule]

        init(rules: [any DispenseTierRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseTier]) -> [String: [String]] {
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

    static func defaultDispenseTierValidator() -> DispenseTierValidator {
        return DispenseTierValidator(
            rules: [
                DispenseTierNameLengthRule(maxLength: 3600),
                DispenseTierCodePrefixRule(prefix: "OPS"),
                DispenseTierRequiredCountryRule(message: "dispense tier needs this field"),
                DispenseTierClinicianIDLengthRule(maxLength: 86400),
                DispenseTierAllowedCodeRule(allowed: []),
            ]
        )
    }
}
