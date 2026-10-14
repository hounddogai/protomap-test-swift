import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict census template must pass. Check returns its problems, or none.
    protocol StrictCensusTemplateRule {
        func check(_ item: StrictCensusTemplate) -> [String]
    }

    final class StrictCensusTemplateCodeLengthRule: StrictCensusTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCensusTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCensusTemplateApprovedGuardRule: StrictCensusTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictCensusTemplate) -> [String] {
            if item.approved && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class StrictCensusTemplateRequiredDescriptionRule: StrictCensusTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCensusTemplate) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCensusTemplateAllowedCodeRule: StrictCensusTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictCensusTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a strict census template.
    final class StrictCensusTemplateValidator {
        var rules: [any StrictCensusTemplateRule]

        init(rules: [any StrictCensusTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCensusTemplate) -> [String] {
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

        func requireValid(_ item: StrictCensusTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCensusTemplate]) -> [String: [String]] {
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

    static func defaultStrictCensusTemplateValidator() -> StrictCensusTemplateValidator {
        return StrictCensusTemplateValidator(
            rules: [
                StrictCensusTemplateCodeLengthRule(maxLength: 16),
                StrictCensusTemplateApprovedGuardRule(limit: 3600),
                StrictCensusTemplateRequiredDescriptionRule(message: "strict census template needs an entry"),
                StrictCensusTemplateAllowedCodeRule(allowed: ["default", "batched", "primary"]),
            ]
        )
    }
}
