import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary study baseline must pass. Check returns its problems, or none.
    protocol PrimaryStudyBaselineRule {
        func check(_ item: PrimaryStudyBaseline) -> [String]
    }

    final class PrimaryStudyBaselineMaximumRangeRule: PrimaryStudyBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryStudyBaseline) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryStudyBaselineRequiredRegionRule: PrimaryStudyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStudyBaseline) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryStudyBaselineCeilingRangeRule: PrimaryStudyBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryStudyBaseline) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryStudyBaselineLabelLengthRule: PrimaryStudyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryStudyBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryStudyBaselineRequiredLabelRule: PrimaryStudyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStudyBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryStudyBaselineCodePrefixRule: PrimaryStudyBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryStudyBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary study baseline.
    final class PrimaryStudyBaselineValidator {
        var rules: [any PrimaryStudyBaselineRule]

        init(rules: [any PrimaryStudyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryStudyBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryStudyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryStudyBaseline]) -> [String: [String]] {
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

    static func defaultPrimaryStudyBaselineValidator() -> PrimaryStudyBaselineValidator {
        return PrimaryStudyBaselineValidator(
            rules: [
                PrimaryStudyBaselineMaximumRangeRule(min: 0.3, max: 4989.1),
                PrimaryStudyBaselineRequiredRegionRule(message: "primary study baseline needs a value"),
                PrimaryStudyBaselineCeilingRangeRule(min: 0.5, max: 513.4),
                PrimaryStudyBaselineLabelLengthRule(maxLength: 64),
                PrimaryStudyBaselineRequiredLabelRule(message: "primary study baseline needs a value"),
                PrimaryStudyBaselineCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
