import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool target must pass. Check returns its problems, or none.
    protocol FloatPoolTargetRule {
        func check(_ item: FloatPoolTarget) -> [String]
    }

    final class FloatPoolTargetCapacityRangeRule: FloatPoolTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolTarget) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FloatPoolTargetRequiredCodeRule: FloatPoolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolTargetRatioRangeRule: FloatPoolTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolTarget) -> [String] {
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

    final class FloatPoolTargetAllowedNameRule: FloatPoolTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool target.
    final class FloatPoolTargetValidator {
        var rules: [any FloatPoolTargetRule]

        init(rules: [any FloatPoolTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolTarget]) -> [String: [String]] {
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

    static func defaultFloatPoolTargetValidator() -> FloatPoolTargetValidator {
        return FloatPoolTargetValidator(
            rules: [
                FloatPoolTargetCapacityRangeRule(min: 32, max: 1000),
                FloatPoolTargetRequiredCodeRule(message: "float pool target needs an entry"),
                FloatPoolTargetRatioRangeRule(min: 0.9, max: 2716.7),
                FloatPoolTargetAllowedNameRule(allowed: ["batched", "batched"]),
            ]
        )
    }
}
