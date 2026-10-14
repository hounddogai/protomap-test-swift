import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted isolation segment must pass. Check returns its problems, or none.
    protocol WeightedIsolationSegmentRule {
        func check(_ item: WeightedIsolationSegment) -> [String]
    }

    final class WeightedIsolationSegmentCurrencyLengthRule: WeightedIsolationSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedIsolationSegment) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedIsolationSegmentCopayRangeRule: WeightedIsolationSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedIsolationSegment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedIsolationSegmentDurationMinutesRangeRule: WeightedIsolationSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedIsolationSegment) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedIsolationSegmentRequiredCodeRule: WeightedIsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedIsolationSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedIsolationSegmentCodePrefixRule: WeightedIsolationSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedIsolationSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted isolation segment.
    final class WeightedIsolationSegmentValidator {
        var rules: [any WeightedIsolationSegmentRule]

        init(rules: [any WeightedIsolationSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedIsolationSegment) -> [String] {
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

        func requireValid(_ item: WeightedIsolationSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedIsolationSegment]) -> [String: [String]] {
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

    static func defaultWeightedIsolationSegmentValidator() -> WeightedIsolationSegmentValidator {
        return WeightedIsolationSegmentValidator(
            rules: [
                WeightedIsolationSegmentCurrencyLengthRule(maxLength: 1000),
                WeightedIsolationSegmentCopayRangeRule(min: 0.5, max: 3623.3),
                WeightedIsolationSegmentDurationMinutesRangeRule(min: 120, max: 255),
                WeightedIsolationSegmentRequiredCodeRule(message: "weighted isolation segment needs this field"),
                WeightedIsolationSegmentCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
