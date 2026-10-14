import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure batch must pass. Check returns its problems, or none.
    protocol ClosureBatchRule {
        func check(_ item: ClosureBatch) -> [String]
    }

    final class ClosureBatchGraceDaysRangeRule: ClosureBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureBatch) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClosureBatchCodePrefixRule: ClosureBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureBatchFacilityLengthRule: ClosureBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureBatch) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureBatchMaximumRangeRule: ClosureBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureBatch) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure batch.
    final class ClosureBatchValidator {
        var rules: [any ClosureBatchRule]

        init(rules: [any ClosureBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureBatch]) -> [String: [String]] {
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

    static func defaultClosureBatchValidator() -> ClosureBatchValidator {
        return ClosureBatchValidator(
            rules: [
                ClosureBatchGraceDaysRangeRule(min: 64, max: 80),
                ClosureBatchCodePrefixRule(prefix: "ACM"),
                ClosureBatchFacilityLengthRule(maxLength: 64),
                ClosureBatchMaximumRangeRule(min: 1.0, max: 519.9),
            ]
        )
    }
}
