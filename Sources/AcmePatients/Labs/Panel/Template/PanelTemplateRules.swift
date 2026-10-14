import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel template must pass. Check returns its problems, or none.
    protocol PanelTemplateRule {
        func check(_ item: PanelTemplate) -> [String]
    }

    final class PanelTemplateCodeLengthRule: PanelTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelTemplateRequiredNameRule: PanelTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelTemplateCodePrefixRule: PanelTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelTemplateRequiredFacilityRule: PanelTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelTemplate) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelTemplateAllowedExternalRefRule: PanelTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is too long"]
            }
            return []
        }
    }

    final class PanelTemplateMinimumRangeRule: PanelTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelTemplate) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel template.
    final class PanelTemplateValidator {
        var rules: [any PanelTemplateRule]

        init(rules: [any PanelTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelTemplate]) -> [String: [String]] {
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

    static func defaultPanelTemplateValidator() -> PanelTemplateValidator {
        return PanelTemplateValidator(
            rules: [
                PanelTemplateCodeLengthRule(maxLength: 32),
                PanelTemplateRequiredNameRule(message: "panel template needs an entry"),
                PanelTemplateCodePrefixRule(prefix: "X"),
                PanelTemplateRequiredFacilityRule(message: "panel template needs this field"),
                PanelTemplateAllowedExternalRefRule(allowed: ["pending"]),
                PanelTemplateMinimumRangeRule(min: 3.1, max: 2141.2),
            ]
        )
    }
}
