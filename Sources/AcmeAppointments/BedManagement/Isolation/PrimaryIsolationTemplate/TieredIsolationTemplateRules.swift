import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered isolation template must pass. Check returns its problems, or none.
    protocol TieredIsolationTemplateRule {
        func check(_ item: TieredIsolationTemplate) -> [String]
    }

    final class TieredIsolationTemplateLabelLengthRule: TieredIsolationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredIsolationTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredIsolationTemplateThresholdRangeRule: TieredIsolationTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredIsolationTemplate) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredIsolationTemplateRequiredCodeRule: TieredIsolationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredIsolationTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredIsolationTemplateAllowedCodeRule: TieredIsolationTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredIsolationTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class TieredIsolationTemplateRequiredLabelRule: TieredIsolationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredIsolationTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredIsolationTemplateRevisionRangeRule: TieredIsolationTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredIsolationTemplate) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered isolation template.
    final class TieredIsolationTemplateValidator {
        var rules: [any TieredIsolationTemplateRule]

        init(rules: [any TieredIsolationTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredIsolationTemplate) -> [String] {
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

        func requireValid(_ item: TieredIsolationTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredIsolationTemplate]) -> [String: [String]] {
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

    static func defaultTieredIsolationTemplateValidator() -> TieredIsolationTemplateValidator {
        return TieredIsolationTemplateValidator(
            rules: [
                TieredIsolationTemplateLabelLengthRule(maxLength: 32),
                TieredIsolationTemplateThresholdRangeRule(min: 2.6, max: 4636.0),
                TieredIsolationTemplateRequiredCodeRule(message: "tiered isolation template needs this field"),
                TieredIsolationTemplateAllowedCodeRule(allowed: ["manual", "scheduled", "tiered"]),
                TieredIsolationTemplateRequiredLabelRule(message: "tiered isolation template needs a value"),
                TieredIsolationTemplateRevisionRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
