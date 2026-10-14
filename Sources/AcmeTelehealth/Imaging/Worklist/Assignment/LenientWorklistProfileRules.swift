import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient worklist profile must pass. Check returns its problems, or none.
    protocol LenientWorklistProfileRule {
        func check(_ item: LenientWorklistProfile) -> [String]
    }

    final class LenientWorklistProfileRequiredSourceRule: LenientWorklistProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientWorklistProfile) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientWorklistProfileCurrencyLengthRule: LenientWorklistProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientWorklistProfile) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientWorklistProfileScoreRangeRule: LenientWorklistProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientWorklistProfile) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient worklist profile.
    final class LenientWorklistProfileValidator {
        var rules: [any LenientWorklistProfileRule]

        init(rules: [any LenientWorklistProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientWorklistProfile) -> [String] {
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

        func requireValid(_ item: LenientWorklistProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientWorklistProfile]) -> [String: [String]] {
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

    static func defaultLenientWorklistProfileValidator() -> LenientWorklistProfileValidator {
        return LenientWorklistProfileValidator(
            rules: [
                LenientWorklistProfileRequiredSourceRule(message: "lenient worklist profile needs this field"),
                LenientWorklistProfileCurrencyLengthRule(maxLength: 32),
                LenientWorklistProfileScoreRangeRule(min: 9.0, max: 1630.2),
            ]
        )
    }
}
