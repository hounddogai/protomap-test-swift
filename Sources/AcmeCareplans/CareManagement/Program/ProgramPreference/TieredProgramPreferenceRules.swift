import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered program preference must pass. Check returns its problems, or none.
    protocol TieredProgramPreferenceRule {
        func check(_ item: TieredProgramPreference) -> [String]
    }

    final class TieredProgramPreferenceFloorValueRangeRule: TieredProgramPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredProgramPreference) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredProgramPreferenceTitleLengthRule: TieredProgramPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProgramPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProgramPreferenceNameLengthRule: TieredProgramPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProgramPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProgramPreferenceApprovedGuardRule: TieredProgramPreferenceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredProgramPreference) -> [String] {
            if item.approved && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredProgramPreferenceCapacityRangeRule: TieredProgramPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredProgramPreference) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered program preference.
    final class TieredProgramPreferenceValidator {
        var rules: [any TieredProgramPreferenceRule]

        init(rules: [any TieredProgramPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredProgramPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredProgramPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredProgramPreference]) -> [String: [String]] {
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

    static func defaultTieredProgramPreferenceValidator() -> TieredProgramPreferenceValidator {
        return TieredProgramPreferenceValidator(
            rules: [
                TieredProgramPreferenceFloorValueRangeRule(min: 8.2, max: 2969.1),
                TieredProgramPreferenceTitleLengthRule(maxLength: 16),
                TieredProgramPreferenceNameLengthRule(maxLength: 1000),
                TieredProgramPreferenceApprovedGuardRule(limit: 4.2),
                TieredProgramPreferenceCapacityRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
