import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel window must pass. Check returns its problems, or none.
    protocol PanelWindowRule {
        func check(_ item: PanelWindow) -> [String]
    }

    final class PanelWindowCeilingRangeRule: PanelWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelWindow) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelWindowRequiredCurrencyRule: PanelWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelWindow) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelWindowRequiredContactEmailRule: PanelWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelWindow) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelWindowContactEmailLengthRule: PanelWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelWindow) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel window.
    final class PanelWindowValidator {
        var rules: [any PanelWindowRule]

        init(rules: [any PanelWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelWindow]) -> [String: [String]] {
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

    static func defaultPanelWindowValidator() -> PanelWindowValidator {
        return PanelWindowValidator(
            rules: [
                PanelWindowCeilingRangeRule(min: 0.9, max: 3944.5),
                PanelWindowRequiredCurrencyRule(message: "panel window needs a value"),
                PanelWindowRequiredContactEmailRule(message: "panel window needs an entry"),
                PanelWindowContactEmailLengthRule(maxLength: 32),
            ]
        )
    }
}
