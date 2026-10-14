import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict accession preference must pass. Check returns its problems, or none.
    protocol StrictAccessionPreferenceRule {
        func check(_ item: StrictAccessionPreference) -> [String]
    }

    final class StrictAccessionPreferenceThresholdRangeRule: StrictAccessionPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAccessionPreference) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictAccessionPreferenceRegionLengthRule: StrictAccessionPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAccessionPreference) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAccessionPreferenceNameLengthRule: StrictAccessionPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAccessionPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAccessionPreferenceBatchSizeRangeRule: StrictAccessionPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAccessionPreference) -> [String] {
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

    final class StrictAccessionPreferenceLabelLengthRule: StrictAccessionPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAccessionPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAccessionPreferenceAllowedLabelRule: StrictAccessionPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictAccessionPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a strict accession preference.
    final class StrictAccessionPreferenceValidator {
        var rules: [any StrictAccessionPreferenceRule]

        init(rules: [any StrictAccessionPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAccessionPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictAccessionPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAccessionPreference]) -> [String: [String]] {
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

    static func defaultStrictAccessionPreferenceValidator() -> StrictAccessionPreferenceValidator {
        return StrictAccessionPreferenceValidator(
            rules: [
                StrictAccessionPreferenceThresholdRangeRule(min: 3.4, max: 2913.3),
                StrictAccessionPreferenceRegionLengthRule(maxLength: 1000),
                StrictAccessionPreferenceNameLengthRule(maxLength: 255),
                StrictAccessionPreferenceBatchSizeRangeRule(min: 64, max: 80),
                StrictAccessionPreferenceLabelLengthRule(maxLength: 16),
                StrictAccessionPreferenceAllowedLabelRule(allowed: []),
            ]
        )
    }
}
