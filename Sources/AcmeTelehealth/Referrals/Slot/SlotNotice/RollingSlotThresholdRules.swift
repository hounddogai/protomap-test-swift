import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling slot threshold must pass. Check returns its problems, or none.
    protocol RollingSlotThresholdRule {
        func check(_ item: RollingSlotThreshold) -> [String]
    }

    final class RollingSlotThresholdAllowedTitleRule: RollingSlotThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingSlotThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class RollingSlotThresholdCodeLengthRule: RollingSlotThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSlotThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSlotThresholdCreatedAtRangeRule: RollingSlotThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSlotThreshold) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingSlotThresholdReviewerLengthRule: RollingSlotThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSlotThreshold) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling slot threshold.
    final class RollingSlotThresholdValidator {
        var rules: [any RollingSlotThresholdRule]

        init(rules: [any RollingSlotThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSlotThreshold) -> [String] {
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

        func requireValid(_ item: RollingSlotThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSlotThreshold]) -> [String: [String]] {
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

    static func defaultRollingSlotThresholdValidator() -> RollingSlotThresholdValidator {
        return RollingSlotThresholdValidator(
            rules: [
                RollingSlotThresholdAllowedTitleRule(allowed: []),
                RollingSlotThresholdCodeLengthRule(maxLength: 32),
                RollingSlotThresholdCreatedAtRangeRule(min: 16, max: 32),
                RollingSlotThresholdReviewerLengthRule(maxLength: 255),
            ]
        )
    }
}
