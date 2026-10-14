import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel variance must pass. Check returns its problems, or none.
    protocol PanelVarianceRule {
        func check(_ item: PanelVariance) -> [String]
    }

    final class PanelVarianceGraceDaysRangeRule: PanelVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelVariance) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelVarianceAllowedPayerRule: PanelVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is inconsistent"]
            }
            return []
        }
    }

    final class PanelVariancePayerLengthRule: PanelVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelVariance) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelVarianceRequiredCodeRule: PanelVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelVarianceRequiredLabelRule: PanelVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelVarianceTagsLimitRule: PanelVarianceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: PanelVariance) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a panel variance.
    final class PanelVarianceValidator {
        var rules: [any PanelVarianceRule]

        init(rules: [any PanelVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelVariance) -> [String] {
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

        func requireValid(_ item: PanelVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelVariance]) -> [String: [String]] {
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

    static func defaultPanelVarianceValidator() -> PanelVarianceValidator {
        return PanelVarianceValidator(
            rules: [
                PanelVarianceGraceDaysRangeRule(min: 255, max: 255),
                PanelVarianceAllowedPayerRule(allowed: ["batched", "seasonal"]),
                PanelVariancePayerLengthRule(maxLength: 64),
                PanelVarianceRequiredCodeRule(message: "panel variance needs an entry"),
                PanelVarianceRequiredLabelRule(message: "panel variance needs a value"),
                PanelVarianceTagsLimitRule(maxCount: 1000, banned: ["pending"]),
            ]
        )
    }
}
