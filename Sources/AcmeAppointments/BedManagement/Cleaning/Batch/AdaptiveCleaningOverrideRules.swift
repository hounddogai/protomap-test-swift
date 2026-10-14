import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive cleaning override must pass. Check returns its problems, or none.
    protocol AdaptiveCleaningOverrideRule {
        func check(_ item: AdaptiveCleaningOverride) -> [String]
    }

    final class AdaptiveCleaningOverrideAllowedTitleRule: AdaptiveCleaningOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCleaningOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class AdaptiveCleaningOverrideRequiredTitleRule: AdaptiveCleaningOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCleaningOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCleaningOverrideOwnerIDLengthRule: AdaptiveCleaningOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCleaningOverride) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive cleaning override.
    final class AdaptiveCleaningOverrideValidator {
        var rules: [any AdaptiveCleaningOverrideRule]

        init(rules: [any AdaptiveCleaningOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCleaningOverride) -> [String] {
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

        func requireValid(_ item: AdaptiveCleaningOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCleaningOverride]) -> [String: [String]] {
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

    static func defaultAdaptiveCleaningOverrideValidator() -> AdaptiveCleaningOverrideValidator {
        return AdaptiveCleaningOverrideValidator(
            rules: [
                AdaptiveCleaningOverrideAllowedTitleRule(allowed: []),
                AdaptiveCleaningOverrideRequiredTitleRule(message: "adaptive cleaning override needs this field"),
                AdaptiveCleaningOverrideOwnerIDLengthRule(maxLength: 16),
            ]
        )
    }
}
