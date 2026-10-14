import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered inventory score must pass. Check returns its problems, or none.
    protocol TieredInventoryScoreRule {
        func check(_ item: TieredInventoryScore) -> [String]
    }

    final class TieredInventoryScoreCodeLengthRule: TieredInventoryScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredInventoryScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredInventoryScoreCodePrefixRule: TieredInventoryScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredInventoryScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredInventoryScoreRequiredNameRule: TieredInventoryScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredInventoryScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredInventoryScoreAllowedNameRule: TieredInventoryScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredInventoryScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class TieredInventoryScoreNameLengthRule: TieredInventoryScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredInventoryScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered inventory score.
    final class TieredInventoryScoreValidator {
        var rules: [any TieredInventoryScoreRule]

        init(rules: [any TieredInventoryScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredInventoryScore) -> [String] {
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

        func requireValid(_ item: TieredInventoryScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredInventoryScore]) -> [String: [String]] {
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

    static func defaultTieredInventoryScoreValidator() -> TieredInventoryScoreValidator {
        return TieredInventoryScoreValidator(
            rules: [
                TieredInventoryScoreCodeLengthRule(maxLength: 1000),
                TieredInventoryScoreCodePrefixRule(prefix: "X"),
                TieredInventoryScoreRequiredNameRule(message: "tiered inventory score needs this field"),
                TieredInventoryScoreAllowedNameRule(allowed: ["legacy", "manual"]),
                TieredInventoryScoreNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
