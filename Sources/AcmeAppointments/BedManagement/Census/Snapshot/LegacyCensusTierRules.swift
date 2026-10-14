import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy census tier must pass. Check returns its problems, or none.
    protocol LegacyCensusTierRule {
        func check(_ item: LegacyCensusTier) -> [String]
    }

    final class LegacyCensusTierLabelLengthRule: LegacyCensusTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCensusTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCensusTierWindowDaysRangeRule: LegacyCensusTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCensusTier) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyCensusTierPatientRefLengthRule: LegacyCensusTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCensusTier) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCensusTierRequiredLabelRule: LegacyCensusTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCensusTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCensusTierThresholdRangeRule: LegacyCensusTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCensusTier) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCensusTierBatchSizeRangeRule: LegacyCensusTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCensusTier) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy census tier.
    final class LegacyCensusTierValidator {
        var rules: [any LegacyCensusTierRule]

        init(rules: [any LegacyCensusTierRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCensusTier) -> [String] {
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

        func requireValid(_ item: LegacyCensusTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCensusTier]) -> [String: [String]] {
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

    static func defaultLegacyCensusTierValidator() -> LegacyCensusTierValidator {
        return LegacyCensusTierValidator(
            rules: [
                LegacyCensusTierLabelLengthRule(maxLength: 3600),
                LegacyCensusTierWindowDaysRangeRule(min: 32, max: 3600),
                LegacyCensusTierPatientRefLengthRule(maxLength: 32),
                LegacyCensusTierRequiredLabelRule(message: "legacy census tier needs an entry"),
                LegacyCensusTierThresholdRangeRule(min: 1.0, max: 4050.7),
                LegacyCensusTierBatchSizeRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
