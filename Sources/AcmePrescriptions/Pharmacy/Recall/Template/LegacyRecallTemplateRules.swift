import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy recall template must pass. Check returns its problems, or none.
    protocol LegacyRecallTemplateRule {
        func check(_ item: LegacyRecallTemplate) -> [String]
    }

    final class LegacyRecallTemplateClinicianIDLengthRule: LegacyRecallTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallTemplate) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRecallTemplateMinimumRangeRule: LegacyRecallTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyRecallTemplate) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyRecallTemplateTitleLengthRule: LegacyRecallTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRecallTemplateAllowedCodeRule: LegacyRecallTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyRecallTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy recall template.
    final class LegacyRecallTemplateValidator {
        var rules: [any LegacyRecallTemplateRule]

        init(rules: [any LegacyRecallTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRecallTemplate) -> [String] {
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

        func requireValid(_ item: LegacyRecallTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRecallTemplate]) -> [String: [String]] {
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

    static func defaultLegacyRecallTemplateValidator() -> LegacyRecallTemplateValidator {
        return LegacyRecallTemplateValidator(
            rules: [
                LegacyRecallTemplateClinicianIDLengthRule(maxLength: 16),
                LegacyRecallTemplateMinimumRangeRule(min: 10.0, max: 4602.5),
                LegacyRecallTemplateTitleLengthRule(maxLength: 3600),
                LegacyRecallTemplateAllowedCodeRule(allowed: ["fallback"]),
            ]
        )
    }
}
