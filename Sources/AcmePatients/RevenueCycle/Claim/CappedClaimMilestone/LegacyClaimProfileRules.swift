import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy claim profile must pass. Check returns its problems, or none.
    protocol LegacyClaimProfileRule {
        func check(_ item: LegacyClaimProfile) -> [String]
    }

    final class LegacyClaimProfileRequiredNotesRule: LegacyClaimProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyClaimProfile) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyClaimProfileNameLengthRule: LegacyClaimProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyClaimProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyClaimProfileCodeLengthRule: LegacyClaimProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyClaimProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyClaimProfileNotesLengthRule: LegacyClaimProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyClaimProfile) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy claim profile.
    final class LegacyClaimProfileValidator {
        var rules: [any LegacyClaimProfileRule]

        init(rules: [any LegacyClaimProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyClaimProfile) -> [String] {
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

        func requireValid(_ item: LegacyClaimProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyClaimProfile]) -> [String: [String]] {
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

    static func defaultLegacyClaimProfileValidator() -> LegacyClaimProfileValidator {
        return LegacyClaimProfileValidator(
            rules: [
                LegacyClaimProfileRequiredNotesRule(message: "legacy claim profile needs this field"),
                LegacyClaimProfileNameLengthRule(maxLength: 32),
                LegacyClaimProfileCodeLengthRule(maxLength: 64),
                LegacyClaimProfileNotesLengthRule(maxLength: 16),
            ]
        )
    }
}
