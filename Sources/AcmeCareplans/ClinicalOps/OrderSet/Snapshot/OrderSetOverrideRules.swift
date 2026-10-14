import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set override must pass. Check returns its problems, or none.
    protocol OrderSetOverrideRule {
        func check(_ item: OrderSetOverride) -> [String]
    }

    final class OrderSetOverrideAllowedLabelRule: OrderSetOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class OrderSetOverrideCodeLengthRule: OrderSetOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetOverrideTagsLimitRule: OrderSetOverrideRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: OrderSetOverride) -> [String] {
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

    /// Runs every rule of a order set override.
    final class OrderSetOverrideValidator {
        var rules: [any OrderSetOverrideRule]

        init(rules: [any OrderSetOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetOverride]) -> [String: [String]] {
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

    static func defaultOrderSetOverrideValidator() -> OrderSetOverrideValidator {
        return OrderSetOverrideValidator(
            rules: [
                OrderSetOverrideAllowedLabelRule(allowed: []),
                OrderSetOverrideCodeLengthRule(maxLength: 3600),
                OrderSetOverrideTagsLimitRule(maxCount: 120, banned: []),
            ]
        )
    }
}
