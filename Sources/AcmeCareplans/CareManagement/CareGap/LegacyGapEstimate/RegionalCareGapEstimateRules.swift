import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional care gap estimate must pass. Check returns its problems, or none.
    protocol RegionalCareGapEstimateRule {
        func check(_ item: RegionalCareGapEstimate) -> [String]
    }

    final class RegionalCareGapEstimateRequiredCodeRule: RegionalCareGapEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareGapEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareGapEstimateRequiredNotesRule: RegionalCareGapEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareGapEstimate) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareGapEstimateSequenceRangeRule: RegionalCareGapEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCareGapEstimate) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional care gap estimate.
    final class RegionalCareGapEstimateValidator {
        var rules: [any RegionalCareGapEstimateRule]

        init(rules: [any RegionalCareGapEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareGapEstimate) -> [String] {
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

        func requireValid(_ item: RegionalCareGapEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareGapEstimate]) -> [String: [String]] {
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

    static func defaultRegionalCareGapEstimateValidator() -> RegionalCareGapEstimateValidator {
        return RegionalCareGapEstimateValidator(
            rules: [
                RegionalCareGapEstimateRequiredCodeRule(message: "regional care gap estimate needs a value"),
                RegionalCareGapEstimateRequiredNotesRule(message: "regional care gap estimate needs this field"),
                RegionalCareGapEstimateSequenceRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
