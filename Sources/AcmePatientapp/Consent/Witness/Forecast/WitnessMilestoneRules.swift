import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness milestone must pass. Check returns its problems, or none.
    protocol WitnessMilestoneRule {
        func check(_ item: WitnessMilestone) -> [String]
    }

    final class WitnessMilestoneSpecialtyLengthRule: WitnessMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessMilestone) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessMilestoneCodePrefixRule: WitnessMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessMilestoneRequiredTitleRule: WitnessMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessMilestoneRequiredCodeRule: WitnessMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessMilestoneTitleLengthRule: WitnessMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessMilestoneRequiredUnitRule: WitnessMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessMilestone) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness milestone.
    final class WitnessMilestoneValidator {
        var rules: [any WitnessMilestoneRule]

        init(rules: [any WitnessMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessMilestone) -> [String] {
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

        func requireValid(_ item: WitnessMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessMilestone]) -> [String: [String]] {
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

    static func defaultWitnessMilestoneValidator() -> WitnessMilestoneValidator {
        return WitnessMilestoneValidator(
            rules: [
                WitnessMilestoneSpecialtyLengthRule(maxLength: 255),
                WitnessMilestoneCodePrefixRule(prefix: "REF"),
                WitnessMilestoneRequiredTitleRule(message: "witness milestone needs this field"),
                WitnessMilestoneRequiredCodeRule(message: "witness milestone needs an entry"),
                WitnessMilestoneTitleLengthRule(maxLength: 255),
                WitnessMilestoneRequiredUnitRule(message: "witness milestone needs an entry"),
            ]
        )
    }
}
