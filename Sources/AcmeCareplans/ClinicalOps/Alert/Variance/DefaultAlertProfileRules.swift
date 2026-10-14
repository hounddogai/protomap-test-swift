import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default alert profile must pass. Check returns its problems, or none.
    protocol DefaultAlertProfileRule {
        func check(_ item: DefaultAlertProfile) -> [String]
    }

    final class DefaultAlertProfileSpecialtyLengthRule: DefaultAlertProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAlertProfile) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultAlertProfileRequiredSpecialtyRule: DefaultAlertProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAlertProfile) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAlertProfileMaximumRangeRule: DefaultAlertProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultAlertProfile) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultAlertProfileRequiredCodeRule: DefaultAlertProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAlertProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAlertProfileTitleLengthRule: DefaultAlertProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAlertProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default alert profile.
    final class DefaultAlertProfileValidator {
        var rules: [any DefaultAlertProfileRule]

        init(rules: [any DefaultAlertProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAlertProfile) -> [String] {
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

        func requireValid(_ item: DefaultAlertProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAlertProfile]) -> [String: [String]] {
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

    static func defaultDefaultAlertProfileValidator() -> DefaultAlertProfileValidator {
        return DefaultAlertProfileValidator(
            rules: [
                DefaultAlertProfileSpecialtyLengthRule(maxLength: 1000),
                DefaultAlertProfileRequiredSpecialtyRule(message: "default alert profile needs this field"),
                DefaultAlertProfileMaximumRangeRule(min: 3.0, max: 1141.6),
                DefaultAlertProfileRequiredCodeRule(message: "default alert profile needs a value"),
                DefaultAlertProfileTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
