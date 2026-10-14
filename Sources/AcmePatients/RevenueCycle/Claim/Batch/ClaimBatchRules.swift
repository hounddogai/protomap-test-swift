import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim batch must pass. Check returns its problems, or none.
    protocol ClaimBatchRule {
        func check(_ item: ClaimBatch) -> [String]
    }

    final class ClaimBatchWindowDaysRangeRule: ClaimBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimBatch) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimBatchQuantityRangeRule: ClaimBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimBatch) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimBatchRequiredOwnerIDRule: ClaimBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimBatch) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimBatchTitleLengthRule: ClaimBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimBatchApprovedGuardRule: ClaimBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ClaimBatch) -> [String] {
            if item.approved && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ClaimBatchStartsAtRangeRule: ClaimBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimBatch) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim batch.
    final class ClaimBatchValidator {
        var rules: [any ClaimBatchRule]

        init(rules: [any ClaimBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimBatch]) -> [String: [String]] {
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

    static func defaultClaimBatchValidator() -> ClaimBatchValidator {
        return ClaimBatchValidator(
            rules: [
                ClaimBatchWindowDaysRangeRule(min: 16, max: 255),
                ClaimBatchQuantityRangeRule(min: 16, max: 86400),
                ClaimBatchRequiredOwnerIDRule(message: "claim batch needs this field"),
                ClaimBatchTitleLengthRule(maxLength: 120),
                ClaimBatchApprovedGuardRule(limit: 3600),
                ClaimBatchStartsAtRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
