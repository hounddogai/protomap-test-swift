import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool estimate must pass. Check returns its problems, or none.
    protocol FloatPoolEstimateRule {
        func check(_ item: FloatPoolEstimate) -> [String]
    }

    final class FloatPoolEstimateRequiredCodeRule: FloatPoolEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolEstimateArchivedGuardRule: FloatPoolEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FloatPoolEstimate) -> [String] {
            if item.archived && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class FloatPoolEstimateRevisionRangeRule: FloatPoolEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolEstimate) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool estimate.
    final class FloatPoolEstimateValidator {
        var rules: [any FloatPoolEstimateRule]

        init(rules: [any FloatPoolEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolEstimate) -> [String] {
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

        func requireValid(_ item: FloatPoolEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolEstimate]) -> [String: [String]] {
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

    static func defaultFloatPoolEstimateValidator() -> FloatPoolEstimateValidator {
        return FloatPoolEstimateValidator(
            rules: [
                FloatPoolEstimateRequiredCodeRule(message: "float pool estimate needs this field"),
                FloatPoolEstimateArchivedGuardRule(limit: 3600),
                FloatPoolEstimateRevisionRangeRule(min: 16, max: 80),
            ]
        )
    }
}
