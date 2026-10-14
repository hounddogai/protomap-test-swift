import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool variance must pass. Check returns its problems, or none.
    protocol FloatPoolVarianceRule {
        func check(_ item: FloatPoolVariance) -> [String]
    }

    final class FloatPoolVarianceVisibleGuardRule: FloatPoolVarianceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FloatPoolVariance) -> [String] {
            if item.visible && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class FloatPoolVarianceRequiredReviewerRule: FloatPoolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolVariance) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolVarianceReviewerLengthRule: FloatPoolVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolVariance) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolVarianceRequiredNotesRule: FloatPoolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolVariance) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolVarianceNotesLengthRule: FloatPoolVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolVariance) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool variance.
    final class FloatPoolVarianceValidator {
        var rules: [any FloatPoolVarianceRule]

        init(rules: [any FloatPoolVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolVariance]) -> [String: [String]] {
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

    static func defaultFloatPoolVarianceValidator() -> FloatPoolVarianceValidator {
        return FloatPoolVarianceValidator(
            rules: [
                FloatPoolVarianceVisibleGuardRule(limit: 3.4),
                FloatPoolVarianceRequiredReviewerRule(message: "float pool variance needs a value"),
                FloatPoolVarianceReviewerLengthRule(maxLength: 86400),
                FloatPoolVarianceRequiredNotesRule(message: "float pool variance needs this field"),
                FloatPoolVarianceNotesLengthRule(maxLength: 255),
            ]
        )
    }
}
