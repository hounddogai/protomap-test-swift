import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program review must pass. Check returns its problems, or none.
    protocol ProgramReviewRule {
        func check(_ item: ProgramReview) -> [String]
    }

    final class ProgramReviewAttemptsRangeRule: ProgramReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramReview) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramReviewDescriptionLengthRule: ProgramReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramReview) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramReviewCodePrefixRule: ProgramReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramReviewThresholdRangeRule: ProgramReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramReview) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a program review.
    final class ProgramReviewValidator {
        var rules: [any ProgramReviewRule]

        init(rules: [any ProgramReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramReview]) -> [String: [String]] {
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

    static func defaultProgramReviewValidator() -> ProgramReviewValidator {
        return ProgramReviewValidator(
            rules: [
                ProgramReviewAttemptsRangeRule(min: 64, max: 80),
                ProgramReviewDescriptionLengthRule(maxLength: 255),
                ProgramReviewCodePrefixRule(prefix: "REF"),
                ProgramReviewThresholdRangeRule(min: 4.1, max: 2536.8),
            ]
        )
    }
}
