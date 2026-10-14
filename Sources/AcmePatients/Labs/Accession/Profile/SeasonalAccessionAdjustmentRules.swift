import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal accession adjustment must pass. Check returns its problems, or none.
    protocol SeasonalAccessionAdjustmentRule {
        func check(_ item: SeasonalAccessionAdjustment) -> [String]
    }

    final class SeasonalAccessionAdjustmentRequiredCodeRule: SeasonalAccessionAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAccessionAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalAccessionAdjustmentFloorValueRangeRule: SeasonalAccessionAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAccessionAdjustment) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalAccessionAdjustmentMinimumRangeRule: SeasonalAccessionAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAccessionAdjustment) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalAccessionAdjustmentNameLengthRule: SeasonalAccessionAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAccessionAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal accession adjustment.
    final class SeasonalAccessionAdjustmentValidator {
        var rules: [any SeasonalAccessionAdjustmentRule]

        init(rules: [any SeasonalAccessionAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAccessionAdjustment) -> [String] {
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

        func requireValid(_ item: SeasonalAccessionAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAccessionAdjustment]) -> [String: [String]] {
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

    static func defaultSeasonalAccessionAdjustmentValidator() -> SeasonalAccessionAdjustmentValidator {
        return SeasonalAccessionAdjustmentValidator(
            rules: [
                SeasonalAccessionAdjustmentRequiredCodeRule(message: "seasonal accession adjustment needs this field"),
                SeasonalAccessionAdjustmentFloorValueRangeRule(min: 1.3, max: 2281.6),
                SeasonalAccessionAdjustmentMinimumRangeRule(min: 4.2, max: 4762.8),
                SeasonalAccessionAdjustmentNameLengthRule(maxLength: 255),
            ]
        )
    }
}
