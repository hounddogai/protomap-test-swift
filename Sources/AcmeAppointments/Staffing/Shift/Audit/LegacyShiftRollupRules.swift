import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy shift rollup must pass. Check returns its problems, or none.
    protocol LegacyShiftRollupRule {
        func check(_ item: LegacyShiftRollup) -> [String]
    }

    final class LegacyShiftRollupRegionLengthRule: LegacyShiftRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyShiftRollup) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyShiftRollupRatioRangeRule: LegacyShiftRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyShiftRollup) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyShiftRollupEncounterIDLengthRule: LegacyShiftRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyShiftRollup) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy shift rollup.
    final class LegacyShiftRollupValidator {
        var rules: [any LegacyShiftRollupRule]

        init(rules: [any LegacyShiftRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyShiftRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyShiftRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyShiftRollup]) -> [String: [String]] {
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

    static func defaultLegacyShiftRollupValidator() -> LegacyShiftRollupValidator {
        return LegacyShiftRollupValidator(
            rules: [
                LegacyShiftRollupRegionLengthRule(maxLength: 16),
                LegacyShiftRollupRatioRangeRule(min: 2.5, max: 4736.4),
                LegacyShiftRollupEncounterIDLengthRule(maxLength: 32),
            ]
        )
    }
}
