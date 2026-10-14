import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched outreach policy must pass. Check returns its problems, or none.
    protocol BatchedOutreachPolicyRule {
        func check(_ item: BatchedOutreachPolicy) -> [String]
    }

    final class BatchedOutreachPolicyMinimumRangeRule: BatchedOutreachPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOutreachPolicy) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedOutreachPolicyRequiredCodeRule: BatchedOutreachPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOutreachPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOutreachPolicyCreatedAtRangeRule: BatchedOutreachPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOutreachPolicy) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedOutreachPolicyRequiredNameRule: BatchedOutreachPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOutreachPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOutreachPolicyDiagnosisCodeLengthRule: BatchedOutreachPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOutreachPolicy) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOutreachPolicyWindowDaysRangeRule: BatchedOutreachPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOutreachPolicy) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched outreach policy.
    final class BatchedOutreachPolicyValidator {
        var rules: [any BatchedOutreachPolicyRule]

        init(rules: [any BatchedOutreachPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOutreachPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedOutreachPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOutreachPolicy]) -> [String: [String]] {
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

    static func defaultBatchedOutreachPolicyValidator() -> BatchedOutreachPolicyValidator {
        return BatchedOutreachPolicyValidator(
            rules: [
                BatchedOutreachPolicyMinimumRangeRule(min: 5.5, max: 1614.1),
                BatchedOutreachPolicyRequiredCodeRule(message: "batched outreach policy needs a value"),
                BatchedOutreachPolicyCreatedAtRangeRule(min: 3600, max: 3600),
                BatchedOutreachPolicyRequiredNameRule(message: "batched outreach policy needs this field"),
                BatchedOutreachPolicyDiagnosisCodeLengthRule(maxLength: 255),
                BatchedOutreachPolicyWindowDaysRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
