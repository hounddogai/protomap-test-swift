import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending care gap batch must pass. Check returns its problems, or none.
    protocol PendingCareGapBatchRule {
        func check(_ item: PendingCareGapBatch) -> [String]
    }

    final class PendingCareGapBatchExpiresAtRangeRule: PendingCareGapBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCareGapBatch) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCareGapBatchRequiredSummaryRule: PendingCareGapBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareGapBatch) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareGapBatchCodeLengthRule: PendingCareGapBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareGapBatchQuantityRangeRule: PendingCareGapBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCareGapBatch) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCareGapBatchAllowedLabelRule: PendingCareGapBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCareGapBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a pending care gap batch.
    final class PendingCareGapBatchValidator {
        var rules: [any PendingCareGapBatchRule]

        init(rules: [any PendingCareGapBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCareGapBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCareGapBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCareGapBatch]) -> [String: [String]] {
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

    static func defaultPendingCareGapBatchValidator() -> PendingCareGapBatchValidator {
        return PendingCareGapBatchValidator(
            rules: [
                PendingCareGapBatchExpiresAtRangeRule(min: 16, max: 86400),
                PendingCareGapBatchRequiredSummaryRule(message: "pending care gap batch needs a value"),
                PendingCareGapBatchCodeLengthRule(maxLength: 120),
                PendingCareGapBatchQuantityRangeRule(min: 80, max: 1000),
                PendingCareGapBatchAllowedLabelRule(allowed: ["capped"]),
            ]
        )
    }
}
