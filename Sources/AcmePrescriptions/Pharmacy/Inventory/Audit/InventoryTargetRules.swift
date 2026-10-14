import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory target must pass. Check returns its problems, or none.
    protocol InventoryTargetRule {
        func check(_ item: InventoryTarget) -> [String]
    }

    final class InventoryTargetVisibleGuardRule: InventoryTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: InventoryTarget) -> [String] {
            if item.visible && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class InventoryTargetTagsLimitRule: InventoryTargetRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: InventoryTarget) -> [String] {
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

    final class InventoryTargetAllowedNameRule: InventoryTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class InventoryTargetRequiredCodeRule: InventoryTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryTargetRequiredNameRule: InventoryTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryTargetNameLengthRule: InventoryTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory target.
    final class InventoryTargetValidator {
        var rules: [any InventoryTargetRule]

        init(rules: [any InventoryTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryTarget) -> [String] {
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

        func requireValid(_ item: InventoryTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryTarget]) -> [String: [String]] {
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

    static func defaultInventoryTargetValidator() -> InventoryTargetValidator {
        return InventoryTargetValidator(
            rules: [
                InventoryTargetVisibleGuardRule(limit: 80),
                InventoryTargetTagsLimitRule(maxCount: 32, banned: ["tiered", "scheduled"]),
                InventoryTargetAllowedNameRule(allowed: []),
                InventoryTargetRequiredCodeRule(message: "inventory target needs a value"),
                InventoryTargetRequiredNameRule(message: "inventory target needs an entry"),
                InventoryTargetNameLengthRule(maxLength: 32),
            ]
        )
    }
}
