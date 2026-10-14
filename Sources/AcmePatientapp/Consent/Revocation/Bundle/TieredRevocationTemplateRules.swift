import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered revocation template must pass. Check returns its problems, or none.
    protocol TieredRevocationTemplateRule {
        func check(_ item: TieredRevocationTemplate) -> [String]
    }

    final class TieredRevocationTemplateSequenceRangeRule: TieredRevocationTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRevocationTemplate) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRevocationTemplateRequiredCodeRule: TieredRevocationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRevocationTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRevocationTemplateAllowedLabelRule: TieredRevocationTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredRevocationTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class TieredRevocationTemplateCodePrefixRule: TieredRevocationTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredRevocationTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredRevocationTemplateLabelLengthRule: TieredRevocationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRevocationTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered revocation template.
    final class TieredRevocationTemplateValidator {
        var rules: [any TieredRevocationTemplateRule]

        init(rules: [any TieredRevocationTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRevocationTemplate) -> [String] {
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

        func requireValid(_ item: TieredRevocationTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRevocationTemplate]) -> [String: [String]] {
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

    static func defaultTieredRevocationTemplateValidator() -> TieredRevocationTemplateValidator {
        return TieredRevocationTemplateValidator(
            rules: [
                TieredRevocationTemplateSequenceRangeRule(min: 16, max: 64),
                TieredRevocationTemplateRequiredCodeRule(message: "tiered revocation template needs an entry"),
                TieredRevocationTemplateAllowedLabelRule(allowed: ["weighted"]),
                TieredRevocationTemplateCodePrefixRule(prefix: "X"),
                TieredRevocationTemplateLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
