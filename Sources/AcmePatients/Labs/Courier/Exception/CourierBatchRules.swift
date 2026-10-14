import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier batch must pass. Check returns its problems, or none.
    protocol CourierBatchRule {
        func check(_ item: CourierBatch) -> [String]
    }

    final class CourierBatchExpiresAtRangeRule: CourierBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierBatch) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierBatchActiveGuardRule: CourierBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CourierBatch) -> [String] {
            if item.active && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class CourierBatchCapacityRangeRule: CourierBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierBatch) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierBatchCodePrefixRule: CourierBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierBatchRequiredPayerRule: CourierBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierBatch) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier batch.
    final class CourierBatchValidator {
        var rules: [any CourierBatchRule]

        init(rules: [any CourierBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierBatch]) -> [String: [String]] {
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

    static func defaultCourierBatchValidator() -> CourierBatchValidator {
        return CourierBatchValidator(
            rules: [
                CourierBatchExpiresAtRangeRule(min: 120, max: 1000),
                CourierBatchActiveGuardRule(limit: 120),
                CourierBatchCapacityRangeRule(min: 80, max: 1000),
                CourierBatchCodePrefixRule(prefix: "REF"),
                CourierBatchRequiredPayerRule(message: "courier batch needs an entry"),
            ]
        )
    }
}
