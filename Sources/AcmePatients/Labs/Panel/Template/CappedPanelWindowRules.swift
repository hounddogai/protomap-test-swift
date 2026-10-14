import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped panel window must pass. Check returns its problems, or none.
    protocol CappedPanelWindowRule {
        func check(_ item: CappedPanelWindow) -> [String]
    }

    final class CappedPanelWindowRequiredCodeRule: CappedPanelWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPanelWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedPanelWindowCostRangeRule: CappedPanelWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedPanelWindow) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedPanelWindowCodePrefixRule: CappedPanelWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedPanelWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedPanelWindowWardLengthRule: CappedPanelWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedPanelWindow) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedPanelWindowAllowedTitleRule: CappedPanelWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedPanelWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a capped panel window.
    final class CappedPanelWindowValidator {
        var rules: [any CappedPanelWindowRule]

        init(rules: [any CappedPanelWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedPanelWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedPanelWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedPanelWindow]) -> [String: [String]] {
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

    static func defaultCappedPanelWindowValidator() -> CappedPanelWindowValidator {
        return CappedPanelWindowValidator(
            rules: [
                CappedPanelWindowRequiredCodeRule(message: "capped panel window needs an entry"),
                CappedPanelWindowCostRangeRule(min: 8.0, max: 2327.3),
                CappedPanelWindowCodePrefixRule(prefix: "OPS"),
                CappedPanelWindowWardLengthRule(maxLength: 64),
                CappedPanelWindowAllowedTitleRule(allowed: []),
            ]
        )
    }
}
