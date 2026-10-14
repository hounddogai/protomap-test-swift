import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled inventory baseline must pass. Check returns its problems, or none.
    protocol ScheduledInventoryBaselineRule {
        func check(_ item: ScheduledInventoryBaseline) -> [String]
    }

    final class ScheduledInventoryBaselineRequiredNameRule: ScheduledInventoryBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledInventoryBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledInventoryBaselineCodeLengthRule: ScheduledInventoryBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledInventoryBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledInventoryBaselineRequiredCodeRule: ScheduledInventoryBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledInventoryBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledInventoryBaselineCodePrefixRule: ScheduledInventoryBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledInventoryBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledInventoryBaselineChannelLengthRule: ScheduledInventoryBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledInventoryBaseline) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledInventoryBaselineAllowedCodeRule: ScheduledInventoryBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledInventoryBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled inventory baseline.
    final class ScheduledInventoryBaselineValidator {
        var rules: [any ScheduledInventoryBaselineRule]

        init(rules: [any ScheduledInventoryBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledInventoryBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledInventoryBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledInventoryBaseline]) -> [String: [String]] {
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

    static func defaultScheduledInventoryBaselineValidator() -> ScheduledInventoryBaselineValidator {
        return ScheduledInventoryBaselineValidator(
            rules: [
                ScheduledInventoryBaselineRequiredNameRule(message: "scheduled inventory baseline needs an entry"),
                ScheduledInventoryBaselineCodeLengthRule(maxLength: 1000),
                ScheduledInventoryBaselineRequiredCodeRule(message: "scheduled inventory baseline needs this field"),
                ScheduledInventoryBaselineCodePrefixRule(prefix: "REF"),
                ScheduledInventoryBaselineChannelLengthRule(maxLength: 80),
                ScheduledInventoryBaselineAllowedCodeRule(allowed: ["global"]),
            ]
        )
    }
}
