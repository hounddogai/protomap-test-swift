import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool adjustment must pass. Check returns its problems, or none.
    protocol FloatPoolAdjustmentRule {
        func check(_ item: FloatPoolAdjustment) -> [String]
    }

    final class FloatPoolAdjustmentRegionLengthRule: FloatPoolAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolAdjustment) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolAdjustmentMarginRangeRule: FloatPoolAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolAdjustment) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolAdjustmentRequiredRegionRule: FloatPoolAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolAdjustment) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a float pool adjustment.
    final class FloatPoolAdjustmentValidator {
        var rules: [any FloatPoolAdjustmentRule]

        init(rules: [any FloatPoolAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolAdjustment]) -> [String: [String]] {
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

    static func defaultFloatPoolAdjustmentValidator() -> FloatPoolAdjustmentValidator {
        return FloatPoolAdjustmentValidator(
            rules: [
                FloatPoolAdjustmentRegionLengthRule(maxLength: 32),
                FloatPoolAdjustmentMarginRangeRule(min: 4.8, max: 680.6),
                FloatPoolAdjustmentRequiredRegionRule(message: "float pool adjustment needs this field"),
            ]
        )
    }
}
