import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling witness review must pass. Check returns its problems, or none.
    protocol RollingWitnessReviewRule {
        func check(_ item: RollingWitnessReview) -> [String]
    }

    final class RollingWitnessReviewCodePrefixRule: RollingWitnessReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingWitnessReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingWitnessReviewCodeLengthRule: RollingWitnessReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWitnessReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingWitnessReviewRequiredCodeRule: RollingWitnessReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingWitnessReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingWitnessReviewClinicianIDLengthRule: RollingWitnessReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWitnessReview) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling witness review.
    final class RollingWitnessReviewValidator {
        var rules: [any RollingWitnessReviewRule]

        init(rules: [any RollingWitnessReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingWitnessReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingWitnessReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingWitnessReview]) -> [String: [String]] {
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

    static func defaultRollingWitnessReviewValidator() -> RollingWitnessReviewValidator {
        return RollingWitnessReviewValidator(
            rules: [
                RollingWitnessReviewCodePrefixRule(prefix: "OPS"),
                RollingWitnessReviewCodeLengthRule(maxLength: 1000),
                RollingWitnessReviewRequiredCodeRule(message: "rolling witness review needs a value"),
                RollingWitnessReviewClinicianIDLengthRule(maxLength: 86400),
            ]
        )
    }
}
