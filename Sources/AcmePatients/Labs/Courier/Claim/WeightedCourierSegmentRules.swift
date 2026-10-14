import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted courier segment must pass. Check returns its problems, or none.
    protocol WeightedCourierSegmentRule {
        func check(_ item: WeightedCourierSegment) -> [String]
    }

    final class WeightedCourierSegmentCodePrefixRule: WeightedCourierSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedCourierSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedCourierSegmentRequiredLabelRule: WeightedCourierSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCourierSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCourierSegmentRatioRangeRule: WeightedCourierSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCourierSegment) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted courier segment.
    final class WeightedCourierSegmentValidator {
        var rules: [any WeightedCourierSegmentRule]

        init(rules: [any WeightedCourierSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCourierSegment) -> [String] {
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

        func requireValid(_ item: WeightedCourierSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCourierSegment]) -> [String: [String]] {
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

    static func defaultWeightedCourierSegmentValidator() -> WeightedCourierSegmentValidator {
        return WeightedCourierSegmentValidator(
            rules: [
                WeightedCourierSegmentCodePrefixRule(prefix: "Q"),
                WeightedCourierSegmentRequiredLabelRule(message: "weighted courier segment needs this field"),
                WeightedCourierSegmentRatioRangeRule(min: 3.4, max: 2715.6),
            ]
        )
    }
}
