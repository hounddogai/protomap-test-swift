import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered modality variance must pass. Check returns its problems, or none.
    protocol TieredModalityVarianceRule {
        func check(_ item: TieredModalityVariance) -> [String]
    }

    final class TieredModalityVarianceCodePrefixRule: TieredModalityVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredModalityVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredModalityVarianceAllowedUnitRule: TieredModalityVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredModalityVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is too long"]
            }
            return []
        }
    }

    final class TieredModalityVarianceNameLengthRule: TieredModalityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredModalityVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredModalityVarianceCodeLengthRule: TieredModalityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredModalityVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredModalityVarianceRequiredUnitRule: TieredModalityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredModalityVariance) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredModalityVarianceRequiredCountryRule: TieredModalityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredModalityVariance) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered modality variance.
    final class TieredModalityVarianceValidator {
        var rules: [any TieredModalityVarianceRule]

        init(rules: [any TieredModalityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredModalityVariance) -> [String] {
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

        func requireValid(_ item: TieredModalityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredModalityVariance]) -> [String: [String]] {
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

    static func defaultTieredModalityVarianceValidator() -> TieredModalityVarianceValidator {
        return TieredModalityVarianceValidator(
            rules: [
                TieredModalityVarianceCodePrefixRule(prefix: "Q"),
                TieredModalityVarianceAllowedUnitRule(allowed: ["batched"]),
                TieredModalityVarianceNameLengthRule(maxLength: 86400),
                TieredModalityVarianceCodeLengthRule(maxLength: 3600),
                TieredModalityVarianceRequiredUnitRule(message: "tiered modality variance needs this field"),
                TieredModalityVarianceRequiredCountryRule(message: "tiered modality variance needs an entry"),
            ]
        )
    }
}
