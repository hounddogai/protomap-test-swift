import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict assessment entry must pass. Check returns its problems, or none.
    protocol StrictAssessmentEntryRule {
        func check(_ item: StrictAssessmentEntry) -> [String]
    }

    final class StrictAssessmentEntryGraceDaysRangeRule: StrictAssessmentEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAssessmentEntry) -> [String] {
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

    final class StrictAssessmentEntryLabelLengthRule: StrictAssessmentEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAssessmentEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAssessmentEntryAllowedCategoryRule: StrictAssessmentEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictAssessmentEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is out of range"]
            }
            return []
        }
    }

    final class StrictAssessmentEntryCodePrefixRule: StrictAssessmentEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictAssessmentEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictAssessmentEntryThresholdRangeRule: StrictAssessmentEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAssessmentEntry) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictAssessmentEntryCodeLengthRule: StrictAssessmentEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAssessmentEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict assessment entry.
    final class StrictAssessmentEntryValidator {
        var rules: [any StrictAssessmentEntryRule]

        init(rules: [any StrictAssessmentEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAssessmentEntry) -> [String] {
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

        func requireValid(_ item: StrictAssessmentEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAssessmentEntry]) -> [String: [String]] {
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

    static func defaultStrictAssessmentEntryValidator() -> StrictAssessmentEntryValidator {
        return StrictAssessmentEntryValidator(
            rules: [
                StrictAssessmentEntryGraceDaysRangeRule(min: 16, max: 120),
                StrictAssessmentEntryLabelLengthRule(maxLength: 3600),
                StrictAssessmentEntryAllowedCategoryRule(allowed: []),
                StrictAssessmentEntryCodePrefixRule(prefix: "OPS"),
                StrictAssessmentEntryThresholdRangeRule(min: 7.8, max: 1961.0),
                StrictAssessmentEntryCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
