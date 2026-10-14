import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted language tier must pass. Check returns its problems, or none.
    protocol WeightedLanguageTierRule {
        func check(_ item: WeightedLanguageTier) -> [String]
    }

    final class WeightedLanguageTierRequiredPatientRefRule: WeightedLanguageTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedLanguageTier) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedLanguageTierAllowedCodeRule: WeightedLanguageTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedLanguageTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class WeightedLanguageTierRequiredTitleRule: WeightedLanguageTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedLanguageTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedLanguageTierCodePrefixRule: WeightedLanguageTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedLanguageTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedLanguageTierCodeLengthRule: WeightedLanguageTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedLanguageTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted language tier.
    final class WeightedLanguageTierValidator {
        var rules: [any WeightedLanguageTierRule]

        init(rules: [any WeightedLanguageTierRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedLanguageTier) -> [String] {
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

        func requireValid(_ item: WeightedLanguageTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedLanguageTier]) -> [String: [String]] {
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

    static func defaultWeightedLanguageTierValidator() -> WeightedLanguageTierValidator {
        return WeightedLanguageTierValidator(
            rules: [
                WeightedLanguageTierRequiredPatientRefRule(message: "weighted language tier needs an entry"),
                WeightedLanguageTierAllowedCodeRule(allowed: ["regional", "weighted", "adaptive"]),
                WeightedLanguageTierRequiredTitleRule(message: "weighted language tier needs this field"),
                WeightedLanguageTierCodePrefixRule(prefix: "OPS"),
                WeightedLanguageTierCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
