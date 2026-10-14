import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional interaction window must pass. Check returns its problems, or none.
    protocol RegionalInteractionWindowRule {
        func check(_ item: RegionalInteractionWindow) -> [String]
    }

    final class RegionalInteractionWindowCodePrefixRule: RegionalInteractionWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalInteractionWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalInteractionWindowAcuityRangeRule: RegionalInteractionWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalInteractionWindow) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalInteractionWindowRequiredExternalRefRule: RegionalInteractionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInteractionWindow) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalInteractionWindowCodeLengthRule: RegionalInteractionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalInteractionWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalInteractionWindowRequiredSummaryRule: RegionalInteractionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInteractionWindow) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalInteractionWindowTitleLengthRule: RegionalInteractionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalInteractionWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional interaction window.
    final class RegionalInteractionWindowValidator {
        var rules: [any RegionalInteractionWindowRule]

        init(rules: [any RegionalInteractionWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalInteractionWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalInteractionWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalInteractionWindow]) -> [String: [String]] {
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

    static func defaultRegionalInteractionWindowValidator() -> RegionalInteractionWindowValidator {
        return RegionalInteractionWindowValidator(
            rules: [
                RegionalInteractionWindowCodePrefixRule(prefix: "OPS"),
                RegionalInteractionWindowAcuityRangeRule(min: 80, max: 80),
                RegionalInteractionWindowRequiredExternalRefRule(
                    message: "regional interaction window needs an entry"
                ),
                RegionalInteractionWindowCodeLengthRule(maxLength: 80),
                RegionalInteractionWindowRequiredSummaryRule(message: "regional interaction window needs a value"),
                RegionalInteractionWindowTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
