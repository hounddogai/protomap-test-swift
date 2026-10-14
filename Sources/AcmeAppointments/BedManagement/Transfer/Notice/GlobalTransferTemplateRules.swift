import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global transfer template must pass. Check returns its problems, or none.
    protocol GlobalTransferTemplateRule {
        func check(_ item: GlobalTransferTemplate) -> [String]
    }

    final class GlobalTransferTemplateRequiredNameRule: GlobalTransferTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTransferTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalTransferTemplateRequiredSourceRule: GlobalTransferTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTransferTemplate) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalTransferTemplateSourceLengthRule: GlobalTransferTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalTransferTemplate) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalTransferTemplateCodeLengthRule: GlobalTransferTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalTransferTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalTransferTemplateAllowedCountryRule: GlobalTransferTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalTransferTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is expired"]
            }
            return []
        }
    }

    final class GlobalTransferTemplateCopayRangeRule: GlobalTransferTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalTransferTemplate) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global transfer template.
    final class GlobalTransferTemplateValidator {
        var rules: [any GlobalTransferTemplateRule]

        init(rules: [any GlobalTransferTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalTransferTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalTransferTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalTransferTemplate]) -> [String: [String]] {
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

    static func defaultGlobalTransferTemplateValidator() -> GlobalTransferTemplateValidator {
        return GlobalTransferTemplateValidator(
            rules: [
                GlobalTransferTemplateRequiredNameRule(message: "global transfer template needs a value"),
                GlobalTransferTemplateRequiredSourceRule(message: "global transfer template needs a value"),
                GlobalTransferTemplateSourceLengthRule(maxLength: 64),
                GlobalTransferTemplateCodeLengthRule(maxLength: 1000),
                GlobalTransferTemplateAllowedCountryRule(allowed: ["tiered", "pending"]),
                GlobalTransferTemplateCopayRangeRule(min: 1.6, max: 1610.2),
            ]
        )
    }
}
