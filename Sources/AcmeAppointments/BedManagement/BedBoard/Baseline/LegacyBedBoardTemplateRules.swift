import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy bed board template must pass. Check returns its problems, or none.
    protocol LegacyBedBoardTemplateRule {
        func check(_ item: LegacyBedBoardTemplate) -> [String]
    }

    final class LegacyBedBoardTemplateLabelLengthRule: LegacyBedBoardTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyBedBoardTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyBedBoardTemplateRequiredPayerRule: LegacyBedBoardTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyBedBoardTemplate) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyBedBoardTemplateAllowedPayerRule: LegacyBedBoardTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyBedBoardTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is below minimum"]
            }
            return []
        }
    }

    final class LegacyBedBoardTemplateFacilityLengthRule: LegacyBedBoardTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyBedBoardTemplate) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyBedBoardTemplatePayerLengthRule: LegacyBedBoardTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyBedBoardTemplate) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy bed board template.
    final class LegacyBedBoardTemplateValidator {
        var rules: [any LegacyBedBoardTemplateRule]

        init(rules: [any LegacyBedBoardTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyBedBoardTemplate) -> [String] {
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

        func requireValid(_ item: LegacyBedBoardTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyBedBoardTemplate]) -> [String: [String]] {
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

    static func defaultLegacyBedBoardTemplateValidator() -> LegacyBedBoardTemplateValidator {
        return LegacyBedBoardTemplateValidator(
            rules: [
                LegacyBedBoardTemplateLabelLengthRule(maxLength: 255),
                LegacyBedBoardTemplateRequiredPayerRule(message: "legacy bed board template needs a value"),
                LegacyBedBoardTemplateAllowedPayerRule(allowed: ["rolling", "weighted"]),
                LegacyBedBoardTemplateFacilityLengthRule(maxLength: 64),
                LegacyBedBoardTemplatePayerLengthRule(maxLength: 86400),
            ]
        )
    }
}
