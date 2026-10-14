import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default closure request must pass. Check returns its problems, or none.
    protocol DefaultClosureRequestRule {
        func check(_ item: DefaultClosureRequest) -> [String]
    }

    final class DefaultClosureRequestRequiredTitleRule: DefaultClosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultClosureRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultClosureRequestUpdatedAtRangeRule: DefaultClosureRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultClosureRequest) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultClosureRequestDiscountRangeRule: DefaultClosureRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultClosureRequest) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultClosureRequestCodePrefixRule: DefaultClosureRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultClosureRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultClosureRequestTagsLimitRule: DefaultClosureRequestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: DefaultClosureRequest) -> [String] {
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

    /// Runs every rule of a default closure request.
    final class DefaultClosureRequestValidator {
        var rules: [any DefaultClosureRequestRule]

        init(rules: [any DefaultClosureRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultClosureRequest) -> [String] {
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

        func requireValid(_ item: DefaultClosureRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultClosureRequest]) -> [String: [String]] {
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

    static func defaultDefaultClosureRequestValidator() -> DefaultClosureRequestValidator {
        return DefaultClosureRequestValidator(
            rules: [
                DefaultClosureRequestRequiredTitleRule(message: "default closure request needs this field"),
                DefaultClosureRequestUpdatedAtRangeRule(min: 32, max: 86400),
                DefaultClosureRequestDiscountRangeRule(min: 4.5, max: 3864.9),
                DefaultClosureRequestCodePrefixRule(prefix: "Q"),
                DefaultClosureRequestTagsLimitRule(maxCount: 64, banned: ["capped", "strict", "weighted"]),
            ]
        )
    }
}
