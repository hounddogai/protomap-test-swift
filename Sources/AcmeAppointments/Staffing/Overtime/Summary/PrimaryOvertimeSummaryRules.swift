import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary overtime summary must pass. Check returns its problems, or none.
    protocol PrimaryOvertimeSummaryRule {
        func check(_ item: PrimaryOvertimeSummary) -> [String]
    }

    final class PrimaryOvertimeSummaryCountryLengthRule: PrimaryOvertimeSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOvertimeSummary) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOvertimeSummaryRequiredCountryRule: PrimaryOvertimeSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOvertimeSummary) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOvertimeSummaryThresholdRangeRule: PrimaryOvertimeSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOvertimeSummary) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryOvertimeSummaryRequiredCodeRule: PrimaryOvertimeSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOvertimeSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOvertimeSummaryDescriptionLengthRule: PrimaryOvertimeSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOvertimeSummary) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOvertimeSummaryUpdatedAtRangeRule: PrimaryOvertimeSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOvertimeSummary) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary overtime summary.
    final class PrimaryOvertimeSummaryValidator {
        var rules: [any PrimaryOvertimeSummaryRule]

        init(rules: [any PrimaryOvertimeSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOvertimeSummary) -> [String] {
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

        func requireValid(_ item: PrimaryOvertimeSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOvertimeSummary]) -> [String: [String]] {
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

    static func defaultPrimaryOvertimeSummaryValidator() -> PrimaryOvertimeSummaryValidator {
        return PrimaryOvertimeSummaryValidator(
            rules: [
                PrimaryOvertimeSummaryCountryLengthRule(maxLength: 255),
                PrimaryOvertimeSummaryRequiredCountryRule(message: "primary overtime summary needs an entry"),
                PrimaryOvertimeSummaryThresholdRangeRule(min: 0.7, max: 4803.7),
                PrimaryOvertimeSummaryRequiredCodeRule(message: "primary overtime summary needs an entry"),
                PrimaryOvertimeSummaryDescriptionLengthRule(maxLength: 32),
                PrimaryOvertimeSummaryUpdatedAtRangeRule(min: 16, max: 16),
            ]
        )
    }
}
