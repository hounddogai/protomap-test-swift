import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan batch must pass. Check returns its problems, or none.
    protocol AcuityPlanBatchRule {
        func check(_ item: AcuityPlanBatch) -> [String]
    }

    final class AcuityPlanBatchTitleLengthRule: AcuityPlanBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanBatchAllergyLengthRule: AcuityPlanBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanBatch) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanBatchCodePrefixRule: AcuityPlanBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanBatchExpiresAtRangeRule: AcuityPlanBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanBatch) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanBatchRequiredTitleRule: AcuityPlanBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanBatchDosageMgRangeRule: AcuityPlanBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanBatch) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan batch.
    final class AcuityPlanBatchValidator {
        var rules: [any AcuityPlanBatchRule]

        init(rules: [any AcuityPlanBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanBatch]) -> [String: [String]] {
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

    static func defaultAcuityPlanBatchValidator() -> AcuityPlanBatchValidator {
        return AcuityPlanBatchValidator(
            rules: [
                AcuityPlanBatchTitleLengthRule(maxLength: 64),
                AcuityPlanBatchAllergyLengthRule(maxLength: 1000),
                AcuityPlanBatchCodePrefixRule(prefix: "ACM"),
                AcuityPlanBatchExpiresAtRangeRule(min: 64, max: 1000),
                AcuityPlanBatchRequiredTitleRule(message: "acuity plan batch needs a value"),
                AcuityPlanBatchDosageMgRangeRule(min: 2.9, max: 4095.1),
            ]
        )
    }
}
