import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot threshold must pass. Check returns its problems, or none.
    protocol SlotThresholdRule {
        func check(_ item: SlotThreshold) -> [String]
    }

    final class SlotThresholdCodeLengthRule: SlotThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotThresholdRequiredCodeRule: SlotThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotThresholdAllowedTitleRule: SlotThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SlotThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class SlotThresholdEncounterIDLengthRule: SlotThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotThreshold) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotThresholdCodePrefixRule: SlotThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot threshold.
    final class SlotThresholdValidator {
        var rules: [any SlotThresholdRule]

        init(rules: [any SlotThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotThreshold]) -> [String: [String]] {
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

    static func defaultSlotThresholdValidator() -> SlotThresholdValidator {
        return SlotThresholdValidator(
            rules: [
                SlotThresholdCodeLengthRule(maxLength: 1000),
                SlotThresholdRequiredCodeRule(message: "slot threshold needs this field"),
                SlotThresholdAllowedTitleRule(allowed: ["manual", "fallback", "weighted"]),
                SlotThresholdEncounterIDLengthRule(maxLength: 86400),
                SlotThresholdCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
