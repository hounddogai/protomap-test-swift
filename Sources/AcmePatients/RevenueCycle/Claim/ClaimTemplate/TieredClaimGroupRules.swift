import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered claim group must pass. Check returns its problems, or none.
    protocol TieredClaimGroupRule {
        func check(_ item: TieredClaimGroup) -> [String]
    }

    final class TieredClaimGroupAllowedCodeRule: TieredClaimGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredClaimGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class TieredClaimGroupCountryLengthRule: TieredClaimGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimGroup) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimGroupEndsAtRangeRule: TieredClaimGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredClaimGroup) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredClaimGroupRequiredCountryRule: TieredClaimGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimGroup) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimGroupNotesLengthRule: TieredClaimGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimGroup) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimGroupRequiredNotesRule: TieredClaimGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimGroup) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered claim group.
    final class TieredClaimGroupValidator {
        var rules: [any TieredClaimGroupRule]

        init(rules: [any TieredClaimGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClaimGroup) -> [String] {
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

        func requireValid(_ item: TieredClaimGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClaimGroup]) -> [String: [String]] {
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

    static func defaultTieredClaimGroupValidator() -> TieredClaimGroupValidator {
        return TieredClaimGroupValidator(
            rules: [
                TieredClaimGroupAllowedCodeRule(allowed: ["rolling", "manual"]),
                TieredClaimGroupCountryLengthRule(maxLength: 80),
                TieredClaimGroupEndsAtRangeRule(min: 80, max: 1000),
                TieredClaimGroupRequiredCountryRule(message: "tiered claim group needs this field"),
                TieredClaimGroupNotesLengthRule(maxLength: 64),
                TieredClaimGroupRequiredNotesRule(message: "tiered claim group needs an entry"),
            ]
        )
    }
}
