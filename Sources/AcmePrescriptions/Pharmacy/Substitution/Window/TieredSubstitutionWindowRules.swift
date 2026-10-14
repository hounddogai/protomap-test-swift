import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered substitution window must pass. Check returns its problems, or none.
    protocol TieredSubstitutionWindowRule {
        func check(_ item: TieredSubstitutionWindow) -> [String]
    }

    final class TieredSubstitutionWindowAllowedNameRule: TieredSubstitutionWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredSubstitutionWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class TieredSubstitutionWindowProcedureCodeLengthRule: TieredSubstitutionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSubstitutionWindow) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSubstitutionWindowRequiredLabelRule: TieredSubstitutionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredSubstitutionWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredSubstitutionWindowCodePrefixRule: TieredSubstitutionWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredSubstitutionWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered substitution window.
    final class TieredSubstitutionWindowValidator {
        var rules: [any TieredSubstitutionWindowRule]

        init(rules: [any TieredSubstitutionWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSubstitutionWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredSubstitutionWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSubstitutionWindow]) -> [String: [String]] {
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

    static func defaultTieredSubstitutionWindowValidator() -> TieredSubstitutionWindowValidator {
        return TieredSubstitutionWindowValidator(
            rules: [
                TieredSubstitutionWindowAllowedNameRule(allowed: ["capped"]),
                TieredSubstitutionWindowProcedureCodeLengthRule(maxLength: 80),
                TieredSubstitutionWindowRequiredLabelRule(message: "tiered substitution window needs this field"),
                TieredSubstitutionWindowCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
