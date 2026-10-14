import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient reference range variance must pass. Check returns its problems, or none.
    protocol LenientReferenceRangeVarianceRule {
        func check(_ item: LenientReferenceRangeVariance) -> [String]
    }

    final class LenientReferenceRangeVarianceTitleLengthRule: LenientReferenceRangeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferenceRangeVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeVarianceNameLengthRule: LenientReferenceRangeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferenceRangeVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeVarianceRequiredNameRule: LenientReferenceRangeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeVariance) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient reference range variance.
    final class LenientReferenceRangeVarianceValidator {
        var rules: [any LenientReferenceRangeVarianceRule]

        init(rules: [any LenientReferenceRangeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReferenceRangeVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientReferenceRangeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReferenceRangeVariance]) -> [String: [String]] {
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

    static func defaultLenientReferenceRangeVarianceValidator() -> LenientReferenceRangeVarianceValidator {
        return LenientReferenceRangeVarianceValidator(
            rules: [
                LenientReferenceRangeVarianceTitleLengthRule(maxLength: 255),
                LenientReferenceRangeVarianceNameLengthRule(maxLength: 120),
                LenientReferenceRangeVarianceRequiredNameRule(
                    message: "lenient reference range variance needs a value"
                ),
            ]
        )
    }
}
