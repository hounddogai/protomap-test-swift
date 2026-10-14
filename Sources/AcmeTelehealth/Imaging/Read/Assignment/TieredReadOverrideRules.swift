import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered read override must pass. Check returns its problems, or none.
    protocol TieredReadOverrideRule {
        func check(_ item: TieredReadOverride) -> [String]
    }

    final class TieredReadOverrideBedLengthRule: TieredReadOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadOverride) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadOverrideCodeLengthRule: TieredReadOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadOverrideAllowedEncounterIDRule: TieredReadOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredReadOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is below minimum"]
            }
            return []
        }
    }

    final class TieredReadOverrideRequiredLabelRule: TieredReadOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadOverrideEncounterIDLengthRule: TieredReadOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadOverride) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadOverrideCodePrefixRule: TieredReadOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredReadOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered read override.
    final class TieredReadOverrideValidator {
        var rules: [any TieredReadOverrideRule]

        init(rules: [any TieredReadOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReadOverride) -> [String] {
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

        func requireValid(_ item: TieredReadOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReadOverride]) -> [String: [String]] {
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

    static func defaultTieredReadOverrideValidator() -> TieredReadOverrideValidator {
        return TieredReadOverrideValidator(
            rules: [
                TieredReadOverrideBedLengthRule(maxLength: 120),
                TieredReadOverrideCodeLengthRule(maxLength: 1000),
                TieredReadOverrideAllowedEncounterIDRule(allowed: []),
                TieredReadOverrideRequiredLabelRule(message: "tiered read override needs an entry"),
                TieredReadOverrideEncounterIDLengthRule(maxLength: 64),
                TieredReadOverrideCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
