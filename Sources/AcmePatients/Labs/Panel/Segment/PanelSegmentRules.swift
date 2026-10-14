import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel segment must pass. Check returns its problems, or none.
    protocol PanelSegmentRule {
        func check(_ item: PanelSegment) -> [String]
    }

    final class PanelSegmentAllowedLabelRule: PanelSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class PanelSegmentBudgetRangeRule: PanelSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelSegment) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelSegmentCodeLengthRule: PanelSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelSegmentRequiredLabelRule: PanelSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelSegmentThresholdRangeRule: PanelSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelSegment) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelSegmentCodePrefixRule: PanelSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel segment.
    final class PanelSegmentValidator {
        var rules: [any PanelSegmentRule]

        init(rules: [any PanelSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelSegment]) -> [String: [String]] {
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

    static func defaultPanelSegmentValidator() -> PanelSegmentValidator {
        return PanelSegmentValidator(
            rules: [
                PanelSegmentAllowedLabelRule(allowed: ["lenient", "lenient", "regional"]),
                PanelSegmentBudgetRangeRule(min: 8.4, max: 1663.2),
                PanelSegmentCodeLengthRule(maxLength: 3600),
                PanelSegmentRequiredLabelRule(message: "panel segment needs this field"),
                PanelSegmentThresholdRangeRule(min: 9.0, max: 421.7),
                PanelSegmentCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
