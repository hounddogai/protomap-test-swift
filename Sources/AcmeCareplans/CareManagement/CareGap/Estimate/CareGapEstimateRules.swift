import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap estimate must pass. Check returns its problems, or none.
    protocol CareGapEstimateRule {
        func check(_ item: CareGapEstimate) -> [String]
    }

    final class CareGapEstimateLabelLengthRule: CareGapEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapEstimateWindowDaysRangeRule: CareGapEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapEstimate) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapEstimateUnitLengthRule: CareGapEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapEstimate) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapEstimateCodeLengthRule: CareGapEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapEstimateAllowedCodeRule: CareGapEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class CareGapEstimateRequiredLabelRule: CareGapEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap estimate.
    final class CareGapEstimateValidator {
        var rules: [any CareGapEstimateRule]

        init(rules: [any CareGapEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapEstimate]) -> [String: [String]] {
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

    static func defaultCareGapEstimateValidator() -> CareGapEstimateValidator {
        return CareGapEstimateValidator(
            rules: [
                CareGapEstimateLabelLengthRule(maxLength: 255),
                CareGapEstimateWindowDaysRangeRule(min: 1000, max: 86400),
                CareGapEstimateUnitLengthRule(maxLength: 64),
                CareGapEstimateCodeLengthRule(maxLength: 3600),
                CareGapEstimateAllowedCodeRule(allowed: ["adaptive"]),
                CareGapEstimateRequiredLabelRule(message: "care gap estimate needs an entry"),
            ]
        )
    }
}
