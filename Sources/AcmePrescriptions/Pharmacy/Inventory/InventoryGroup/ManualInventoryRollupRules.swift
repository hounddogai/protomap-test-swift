import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual inventory rollup must pass. Check returns its problems, or none.
    protocol ManualInventoryRollupRule {
        func check(_ item: ManualInventoryRollup) -> [String]
    }

    final class ManualInventoryRollupRequiredPayerRule: ManualInventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualInventoryRollup) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualInventoryRollupTagsLimitRule: ManualInventoryRollupRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ManualInventoryRollup) -> [String] {
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

    final class ManualInventoryRollupPayerLengthRule: ManualInventoryRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualInventoryRollup) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualInventoryRollupTitleLengthRule: ManualInventoryRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualInventoryRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual inventory rollup.
    final class ManualInventoryRollupValidator {
        var rules: [any ManualInventoryRollupRule]

        init(rules: [any ManualInventoryRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualInventoryRollup) -> [String] {
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

        func requireValid(_ item: ManualInventoryRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualInventoryRollup]) -> [String: [String]] {
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

    static func defaultManualInventoryRollupValidator() -> ManualInventoryRollupValidator {
        return ManualInventoryRollupValidator(
            rules: [
                ManualInventoryRollupRequiredPayerRule(message: "manual inventory rollup needs a value"),
                ManualInventoryRollupTagsLimitRule(maxCount: 80, banned: []),
                ManualInventoryRollupPayerLengthRule(maxLength: 64),
                ManualInventoryRollupTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
