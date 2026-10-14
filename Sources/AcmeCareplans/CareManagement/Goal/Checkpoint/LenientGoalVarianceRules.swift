import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient goal variance must pass. Check returns its problems, or none.
    protocol LenientGoalVarianceRule {
        func check(_ item: LenientGoalVariance) -> [String]
    }

    final class LenientGoalVarianceRequiredLabelRule: LenientGoalVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientGoalVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientGoalVarianceCodeLengthRule: LenientGoalVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientGoalVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientGoalVarianceRequiredNameRule: LenientGoalVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientGoalVariance) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient goal variance.
    final class LenientGoalVarianceValidator {
        var rules: [any LenientGoalVarianceRule]

        init(rules: [any LenientGoalVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientGoalVariance) -> [String] {
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

        func requireValid(_ item: LenientGoalVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientGoalVariance]) -> [String: [String]] {
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

    static func defaultLenientGoalVarianceValidator() -> LenientGoalVarianceValidator {
        return LenientGoalVarianceValidator(
            rules: [
                LenientGoalVarianceRequiredLabelRule(message: "lenient goal variance needs this field"),
                LenientGoalVarianceCodeLengthRule(maxLength: 32),
                LenientGoalVarianceRequiredNameRule(message: "lenient goal variance needs an entry"),
            ]
        )
    }
}
