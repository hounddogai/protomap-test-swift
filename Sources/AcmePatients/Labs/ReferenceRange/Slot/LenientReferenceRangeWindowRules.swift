import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient reference range window must pass. Check returns its problems, or none.
    protocol LenientReferenceRangeWindowRule {
        func check(_ item: LenientReferenceRangeWindow) -> [String]
    }

    final class LenientReferenceRangeWindowSpecialtyLengthRule: LenientReferenceRangeWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferenceRangeWindow) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeWindowRequiredCodeRule: LenientReferenceRangeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferenceRangeWindowRequiredNameRule: LenientReferenceRangeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferenceRangeWindowRateRangeRule: LenientReferenceRangeWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReferenceRangeWindow) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient reference range window.
    final class LenientReferenceRangeWindowValidator {
        var rules: [any LenientReferenceRangeWindowRule]

        init(rules: [any LenientReferenceRangeWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReferenceRangeWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientReferenceRangeWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReferenceRangeWindow]) -> [String: [String]] {
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

    static func defaultLenientReferenceRangeWindowValidator() -> LenientReferenceRangeWindowValidator {
        return LenientReferenceRangeWindowValidator(
            rules: [
                LenientReferenceRangeWindowSpecialtyLengthRule(maxLength: 32),
                LenientReferenceRangeWindowRequiredCodeRule(message: "lenient reference range window needs an entry"),
                LenientReferenceRangeWindowRequiredNameRule(message: "lenient reference range window needs a value"),
                LenientReferenceRangeWindowRateRangeRule(min: 4.3, max: 1904.3),
            ]
        )
    }
}
