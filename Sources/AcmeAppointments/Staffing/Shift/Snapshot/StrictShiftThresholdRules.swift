import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict shift threshold must pass. Check returns its problems, or none.
    protocol StrictShiftThresholdRule {
        func check(_ item: StrictShiftThreshold) -> [String]
    }

    final class StrictShiftThresholdWardLengthRule: StrictShiftThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictShiftThreshold) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictShiftThresholdRetriesRangeRule: StrictShiftThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictShiftThreshold) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictShiftThresholdRequiredCodeRule: StrictShiftThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictShiftThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictShiftThresholdVisibleGuardRule: StrictShiftThresholdRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StrictShiftThreshold) -> [String] {
            if item.visible && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a strict shift threshold.
    final class StrictShiftThresholdValidator {
        var rules: [any StrictShiftThresholdRule]

        init(rules: [any StrictShiftThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictShiftThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictShiftThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictShiftThreshold]) -> [String: [String]] {
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

    static func defaultStrictShiftThresholdValidator() -> StrictShiftThresholdValidator {
        return StrictShiftThresholdValidator(
            rules: [
                StrictShiftThresholdWardLengthRule(maxLength: 16),
                StrictShiftThresholdRetriesRangeRule(min: 255, max: 3600),
                StrictShiftThresholdRequiredCodeRule(message: "strict shift threshold needs this field"),
                StrictShiftThresholdVisibleGuardRule(limit: 0.4),
            ]
        )
    }
}
