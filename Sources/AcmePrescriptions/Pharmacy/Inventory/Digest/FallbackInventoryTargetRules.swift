import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback inventory target must pass. Check returns its problems, or none.
    protocol FallbackInventoryTargetRule {
        func check(_ item: FallbackInventoryTarget) -> [String]
    }

    final class FallbackInventoryTargetNameLengthRule: FallbackInventoryTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackInventoryTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackInventoryTargetSourceLengthRule: FallbackInventoryTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackInventoryTarget) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackInventoryTargetTagsLimitRule: FallbackInventoryTargetRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackInventoryTarget) -> [String] {
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

    final class FallbackInventoryTargetCodePrefixRule: FallbackInventoryTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackInventoryTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackInventoryTargetRequiredSourceRule: FallbackInventoryTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackInventoryTarget) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback inventory target.
    final class FallbackInventoryTargetValidator {
        var rules: [any FallbackInventoryTargetRule]

        init(rules: [any FallbackInventoryTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackInventoryTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackInventoryTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackInventoryTarget]) -> [String: [String]] {
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

    static func defaultFallbackInventoryTargetValidator() -> FallbackInventoryTargetValidator {
        return FallbackInventoryTargetValidator(
            rules: [
                FallbackInventoryTargetNameLengthRule(maxLength: 120),
                FallbackInventoryTargetSourceLengthRule(maxLength: 1000),
                FallbackInventoryTargetTagsLimitRule(maxCount: 120, banned: []),
                FallbackInventoryTargetCodePrefixRule(prefix: "X"),
                FallbackInventoryTargetRequiredSourceRule(message: "fallback inventory target needs a value"),
            ]
        )
    }
}
