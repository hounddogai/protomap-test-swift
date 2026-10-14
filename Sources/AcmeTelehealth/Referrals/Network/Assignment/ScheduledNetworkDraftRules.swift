import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled network draft must pass. Check returns its problems, or none.
    protocol ScheduledNetworkDraftRule {
        func check(_ item: ScheduledNetworkDraft) -> [String]
    }

    final class ScheduledNetworkDraftCodePrefixRule: ScheduledNetworkDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledNetworkDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledNetworkDraftRequiredCodeRule: ScheduledNetworkDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledNetworkDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledNetworkDraftEndsAtRangeRule: ScheduledNetworkDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledNetworkDraft) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledNetworkDraftWindowDaysRangeRule: ScheduledNetworkDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledNetworkDraft) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledNetworkDraftAllowedCodeRule: ScheduledNetworkDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledNetworkDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class ScheduledNetworkDraftNameLengthRule: ScheduledNetworkDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledNetworkDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled network draft.
    final class ScheduledNetworkDraftValidator {
        var rules: [any ScheduledNetworkDraftRule]

        init(rules: [any ScheduledNetworkDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledNetworkDraft) -> [String] {
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

        func requireValid(_ item: ScheduledNetworkDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledNetworkDraft]) -> [String: [String]] {
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

    static func defaultScheduledNetworkDraftValidator() -> ScheduledNetworkDraftValidator {
        return ScheduledNetworkDraftValidator(
            rules: [
                ScheduledNetworkDraftCodePrefixRule(prefix: "Q"),
                ScheduledNetworkDraftRequiredCodeRule(message: "scheduled network draft needs this field"),
                ScheduledNetworkDraftEndsAtRangeRule(min: 80, max: 1000),
                ScheduledNetworkDraftWindowDaysRangeRule(min: 255, max: 255),
                ScheduledNetworkDraftAllowedCodeRule(allowed: []),
                ScheduledNetworkDraftNameLengthRule(maxLength: 16),
            ]
        )
    }
}
