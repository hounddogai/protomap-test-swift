import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global overtime baseline must pass. Check returns its problems, or none.
    protocol GlobalOvertimeBaselineRule {
        func check(_ item: GlobalOvertimeBaseline) -> [String]
    }

    final class GlobalOvertimeBaselineWeightRangeRule: GlobalOvertimeBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOvertimeBaseline) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalOvertimeBaselineCodeLengthRule: GlobalOvertimeBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalOvertimeBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalOvertimeBaselineAllowedRegionRule: GlobalOvertimeBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalOvertimeBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is out of range"]
            }
            return []
        }
    }

    final class GlobalOvertimeBaselineAttemptsRangeRule: GlobalOvertimeBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOvertimeBaseline) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global overtime baseline.
    final class GlobalOvertimeBaselineValidator {
        var rules: [any GlobalOvertimeBaselineRule]

        init(rules: [any GlobalOvertimeBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalOvertimeBaseline) -> [String] {
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

        func requireValid(_ item: GlobalOvertimeBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalOvertimeBaseline]) -> [String: [String]] {
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

    static func defaultGlobalOvertimeBaselineValidator() -> GlobalOvertimeBaselineValidator {
        return GlobalOvertimeBaselineValidator(
            rules: [
                GlobalOvertimeBaselineWeightRangeRule(min: 6.8, max: 4861.9),
                GlobalOvertimeBaselineCodeLengthRule(maxLength: 86400),
                GlobalOvertimeBaselineAllowedRegionRule(allowed: ["strict", "lenient", "weighted"]),
                GlobalOvertimeBaselineAttemptsRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
