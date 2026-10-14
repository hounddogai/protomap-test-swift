import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted task override must pass. Check returns its problems, or none.
    protocol WeightedTaskOverrideRule {
        func check(_ item: WeightedTaskOverride) -> [String]
    }

    final class WeightedTaskOverrideRequiredNameRule: WeightedTaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTaskOverrideCodeLengthRule: WeightedTaskOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTaskOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedTaskOverrideRequiredSegmentRule: WeightedTaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskOverride) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTaskOverrideTagsLimitRule: WeightedTaskOverrideRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: WeightedTaskOverride) -> [String] {
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

    final class WeightedTaskOverrideRequiredCountryRule: WeightedTaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskOverride) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTaskOverrideRequiredCodeRule: WeightedTaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted task override.
    final class WeightedTaskOverrideValidator {
        var rules: [any WeightedTaskOverrideRule]

        init(rules: [any WeightedTaskOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTaskOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedTaskOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTaskOverride]) -> [String: [String]] {
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

    static func defaultWeightedTaskOverrideValidator() -> WeightedTaskOverrideValidator {
        return WeightedTaskOverrideValidator(
            rules: [
                WeightedTaskOverrideRequiredNameRule(message: "weighted task override needs an entry"),
                WeightedTaskOverrideCodeLengthRule(maxLength: 86400),
                WeightedTaskOverrideRequiredSegmentRule(message: "weighted task override needs a value"),
                WeightedTaskOverrideTagsLimitRule(maxCount: 16, banned: ["global", "strict", "default"]),
                WeightedTaskOverrideRequiredCountryRule(message: "weighted task override needs a value"),
                WeightedTaskOverrideRequiredCodeRule(message: "weighted task override needs an entry"),
            ]
        )
    }
}
