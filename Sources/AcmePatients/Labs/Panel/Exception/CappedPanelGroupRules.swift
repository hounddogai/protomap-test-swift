import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped panel group must pass. Check returns its problems, or none.
    protocol CappedPanelGroupRule {
        func check(_ item: CappedPanelGroup) -> [String]
    }

    final class CappedPanelGroupArchivedGuardRule: CappedPanelGroupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedPanelGroup) -> [String] {
            if item.archived && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CappedPanelGroupNameLengthRule: CappedPanelGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedPanelGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedPanelGroupCodePrefixRule: CappedPanelGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedPanelGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedPanelGroupRequiredCodeRule: CappedPanelGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPanelGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedPanelGroupRetriesRangeRule: CappedPanelGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedPanelGroup) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedPanelGroupRequiredNameRule: CappedPanelGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPanelGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped panel group.
    final class CappedPanelGroupValidator {
        var rules: [any CappedPanelGroupRule]

        init(rules: [any CappedPanelGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedPanelGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedPanelGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedPanelGroup]) -> [String: [String]] {
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

    static func defaultCappedPanelGroupValidator() -> CappedPanelGroupValidator {
        return CappedPanelGroupValidator(
            rules: [
                CappedPanelGroupArchivedGuardRule(limit: 32),
                CappedPanelGroupNameLengthRule(maxLength: 64),
                CappedPanelGroupCodePrefixRule(prefix: "OPS"),
                CappedPanelGroupRequiredCodeRule(message: "capped panel group needs an entry"),
                CappedPanelGroupRetriesRangeRule(min: 80, max: 3600),
                CappedPanelGroupRequiredNameRule(message: "capped panel group needs a value"),
            ]
        )
    }
}
