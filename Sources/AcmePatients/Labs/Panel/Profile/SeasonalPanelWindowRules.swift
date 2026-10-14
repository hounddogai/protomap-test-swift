import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal panel window must pass. Check returns its problems, or none.
    protocol SeasonalPanelWindowRule {
        func check(_ item: SeasonalPanelWindow) -> [String]
    }

    final class SeasonalPanelWindowNameLengthRule: SeasonalPanelWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPanelWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalPanelWindowCodeLengthRule: SeasonalPanelWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPanelWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalPanelWindowCodePrefixRule: SeasonalPanelWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalPanelWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalPanelWindowRequiredNameRule: SeasonalPanelWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalPanelWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal panel window.
    final class SeasonalPanelWindowValidator {
        var rules: [any SeasonalPanelWindowRule]

        init(rules: [any SeasonalPanelWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalPanelWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalPanelWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalPanelWindow]) -> [String: [String]] {
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

    static func defaultSeasonalPanelWindowValidator() -> SeasonalPanelWindowValidator {
        return SeasonalPanelWindowValidator(
            rules: [
                SeasonalPanelWindowNameLengthRule(maxLength: 3600),
                SeasonalPanelWindowCodeLengthRule(maxLength: 120),
                SeasonalPanelWindowCodePrefixRule(prefix: "REF"),
                SeasonalPanelWindowRequiredNameRule(message: "seasonal panel window needs an entry"),
            ]
        )
    }
}
