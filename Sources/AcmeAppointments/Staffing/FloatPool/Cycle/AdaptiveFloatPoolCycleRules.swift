import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive float pool cycle must pass. Check returns its problems, or none.
    protocol AdaptiveFloatPoolCycleRule {
        func check(_ item: AdaptiveFloatPoolCycle) -> [String]
    }

    final class AdaptiveFloatPoolCycleBudgetRangeRule: AdaptiveFloatPoolCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFloatPoolCycle) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveFloatPoolCycleLabelLengthRule: AdaptiveFloatPoolCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFloatPoolCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFloatPoolCycleAllowedLabelRule: AdaptiveFloatPoolCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveFloatPoolCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveFloatPoolCycleVersionRangeRule: AdaptiveFloatPoolCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFloatPoolCycle) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveFloatPoolCycleNameLengthRule: AdaptiveFloatPoolCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFloatPoolCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFloatPoolCycleRequiredCodeRule: AdaptiveFloatPoolCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFloatPoolCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive float pool cycle.
    final class AdaptiveFloatPoolCycleValidator {
        var rules: [any AdaptiveFloatPoolCycleRule]

        init(rules: [any AdaptiveFloatPoolCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFloatPoolCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveFloatPoolCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFloatPoolCycle]) -> [String: [String]] {
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

    static func defaultAdaptiveFloatPoolCycleValidator() -> AdaptiveFloatPoolCycleValidator {
        return AdaptiveFloatPoolCycleValidator(
            rules: [
                AdaptiveFloatPoolCycleBudgetRangeRule(min: 4.1, max: 4599.5),
                AdaptiveFloatPoolCycleLabelLengthRule(maxLength: 255),
                AdaptiveFloatPoolCycleAllowedLabelRule(allowed: ["strict"]),
                AdaptiveFloatPoolCycleVersionRangeRule(min: 255, max: 255),
                AdaptiveFloatPoolCycleNameLengthRule(maxLength: 86400),
                AdaptiveFloatPoolCycleRequiredCodeRule(message: "adaptive float pool cycle needs a value"),
            ]
        )
    }
}
