import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan threshold must pass. Check returns its problems, or none.
    protocol AcuityPlanThresholdRule {
        func check(_ item: AcuityPlanThreshold) -> [String]
    }

    final class AcuityPlanThresholdAttemptsRangeRule: AcuityPlanThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanThreshold) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanThresholdRequiredChecksumRule: AcuityPlanThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanThreshold) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanThresholdNameLengthRule: AcuityPlanThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanThresholdReviewerLengthRule: AcuityPlanThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanThreshold) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan threshold.
    final class AcuityPlanThresholdValidator {
        var rules: [any AcuityPlanThresholdRule]

        init(rules: [any AcuityPlanThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanThreshold]) -> [String: [String]] {
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

    static func defaultAcuityPlanThresholdValidator() -> AcuityPlanThresholdValidator {
        return AcuityPlanThresholdValidator(
            rules: [
                AcuityPlanThresholdAttemptsRangeRule(min: 16, max: 3600),
                AcuityPlanThresholdRequiredChecksumRule(message: "acuity plan threshold needs this field"),
                AcuityPlanThresholdNameLengthRule(maxLength: 64),
                AcuityPlanThresholdReviewerLengthRule(maxLength: 32),
            ]
        )
    }
}
