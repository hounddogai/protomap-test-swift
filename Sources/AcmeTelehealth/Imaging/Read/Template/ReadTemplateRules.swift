import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read template must pass. Check returns its problems, or none.
    protocol ReadTemplateRule {
        func check(_ item: ReadTemplate) -> [String]
    }

    final class ReadTemplateRequiredCodeRule: ReadTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadTemplateMarginRangeRule: ReadTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadTemplate) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadTemplateAllowedCodeRule: ReadTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class ReadTemplateWindowDaysRangeRule: ReadTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadTemplate) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadTemplateApprovedGuardRule: ReadTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReadTemplate) -> [String] {
            if item.approved && (item.acuity > limit) {
                return ["acuity \(item.acuity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ReadTemplateLabelLengthRule: ReadTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read template.
    final class ReadTemplateValidator {
        var rules: [any ReadTemplateRule]

        init(rules: [any ReadTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadTemplate]) -> [String: [String]] {
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

    static func defaultReadTemplateValidator() -> ReadTemplateValidator {
        return ReadTemplateValidator(
            rules: [
                ReadTemplateRequiredCodeRule(message: "read template needs an entry"),
                ReadTemplateMarginRangeRule(min: 7.2, max: 1573.9),
                ReadTemplateAllowedCodeRule(allowed: ["rolling", "fallback", "regional"]),
                ReadTemplateWindowDaysRangeRule(min: 32, max: 80),
                ReadTemplateApprovedGuardRule(limit: 16),
                ReadTemplateLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
