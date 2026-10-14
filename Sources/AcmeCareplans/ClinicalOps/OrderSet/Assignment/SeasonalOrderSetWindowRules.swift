import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal order set window must pass. Check returns its problems, or none.
    protocol SeasonalOrderSetWindowRule {
        func check(_ item: SeasonalOrderSetWindow) -> [String]
    }

    final class SeasonalOrderSetWindowCodeLengthRule: SeasonalOrderSetWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOrderSetWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOrderSetWindowRequiredNameRule: SeasonalOrderSetWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalOrderSetWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalOrderSetWindowSpecialtyLengthRule: SeasonalOrderSetWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOrderSetWindow) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOrderSetWindowNameLengthRule: SeasonalOrderSetWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOrderSetWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal order set window.
    final class SeasonalOrderSetWindowValidator {
        var rules: [any SeasonalOrderSetWindowRule]

        init(rules: [any SeasonalOrderSetWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalOrderSetWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalOrderSetWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalOrderSetWindow]) -> [String: [String]] {
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

    static func defaultSeasonalOrderSetWindowValidator() -> SeasonalOrderSetWindowValidator {
        return SeasonalOrderSetWindowValidator(
            rules: [
                SeasonalOrderSetWindowCodeLengthRule(maxLength: 64),
                SeasonalOrderSetWindowRequiredNameRule(message: "seasonal order set window needs a value"),
                SeasonalOrderSetWindowSpecialtyLengthRule(maxLength: 80),
                SeasonalOrderSetWindowNameLengthRule(maxLength: 32),
            ]
        )
    }
}
