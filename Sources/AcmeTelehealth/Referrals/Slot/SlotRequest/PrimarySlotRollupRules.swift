import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary slot rollup must pass. Check returns its problems, or none.
    protocol PrimarySlotRollupRule {
        func check(_ item: PrimarySlotRollup) -> [String]
    }

    final class PrimarySlotRollupRequiredNameRule: PrimarySlotRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySlotRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySlotRollupUpdatedAtRangeRule: PrimarySlotRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySlotRollup) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimarySlotRollupCodeLengthRule: PrimarySlotRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySlotRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySlotRollupCodePrefixRule: PrimarySlotRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimarySlotRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimarySlotRollupAllowedCodeRule: PrimarySlotRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimarySlotRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a primary slot rollup.
    final class PrimarySlotRollupValidator {
        var rules: [any PrimarySlotRollupRule]

        init(rules: [any PrimarySlotRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySlotRollup) -> [String] {
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

        func requireValid(_ item: PrimarySlotRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySlotRollup]) -> [String: [String]] {
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

    static func defaultPrimarySlotRollupValidator() -> PrimarySlotRollupValidator {
        return PrimarySlotRollupValidator(
            rules: [
                PrimarySlotRollupRequiredNameRule(message: "primary slot rollup needs an entry"),
                PrimarySlotRollupUpdatedAtRangeRule(min: 32, max: 1000),
                PrimarySlotRollupCodeLengthRule(maxLength: 64),
                PrimarySlotRollupCodePrefixRule(prefix: "X"),
                PrimarySlotRollupAllowedCodeRule(allowed: ["lenient"]),
            ]
        )
    }
}
