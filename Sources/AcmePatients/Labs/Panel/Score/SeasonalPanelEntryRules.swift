import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal panel entry must pass. Check returns its problems, or none.
    protocol SeasonalPanelEntryRule {
        func check(_ item: SeasonalPanelEntry) -> [String]
    }

    final class SeasonalPanelEntryAllowedCodeRule: SeasonalPanelEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalPanelEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalPanelEntryCodePrefixRule: SeasonalPanelEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalPanelEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalPanelEntryCodeLengthRule: SeasonalPanelEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPanelEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalPanelEntryReviewerLengthRule: SeasonalPanelEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPanelEntry) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal panel entry.
    final class SeasonalPanelEntryValidator {
        var rules: [any SeasonalPanelEntryRule]

        init(rules: [any SeasonalPanelEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalPanelEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalPanelEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalPanelEntry]) -> [String: [String]] {
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

    static func defaultSeasonalPanelEntryValidator() -> SeasonalPanelEntryValidator {
        return SeasonalPanelEntryValidator(
            rules: [
                SeasonalPanelEntryAllowedCodeRule(allowed: ["weighted"]),
                SeasonalPanelEntryCodePrefixRule(prefix: "Q"),
                SeasonalPanelEntryCodeLengthRule(maxLength: 3600),
                SeasonalPanelEntryReviewerLengthRule(maxLength: 80),
            ]
        )
    }
}
