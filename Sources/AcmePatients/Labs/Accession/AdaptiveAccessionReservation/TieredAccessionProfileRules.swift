import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered accession profile must pass. Check returns its problems, or none.
    protocol TieredAccessionProfileRule {
        func check(_ item: TieredAccessionProfile) -> [String]
    }

    final class TieredAccessionProfileCodePrefixRule: TieredAccessionProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredAccessionProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredAccessionProfileRequiredCodeRule: TieredAccessionProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAccessionProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAccessionProfileAllowedCodeRule: TieredAccessionProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredAccessionProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered accession profile.
    final class TieredAccessionProfileValidator {
        var rules: [any TieredAccessionProfileRule]

        init(rules: [any TieredAccessionProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAccessionProfile) -> [String] {
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

        func requireValid(_ item: TieredAccessionProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAccessionProfile]) -> [String: [String]] {
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

    static func defaultTieredAccessionProfileValidator() -> TieredAccessionProfileValidator {
        return TieredAccessionProfileValidator(
            rules: [
                TieredAccessionProfileCodePrefixRule(prefix: "Q"),
                TieredAccessionProfileRequiredCodeRule(message: "tiered accession profile needs this field"),
                TieredAccessionProfileAllowedCodeRule(allowed: ["scheduled", "capped", "primary"]),
            ]
        )
    }
}
