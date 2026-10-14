import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict dispense estimate must pass. Check returns its problems, or none.
    protocol StrictDispenseEstimateRule {
        func check(_ item: StrictDispenseEstimate) -> [String]
    }

    final class StrictDispenseEstimateExpiresAtRangeRule: StrictDispenseEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictDispenseEstimate) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictDispenseEstimateCodeLengthRule: StrictDispenseEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDispenseEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictDispenseEstimateAllowedNameRule: StrictDispenseEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictDispenseEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a strict dispense estimate.
    final class StrictDispenseEstimateValidator {
        var rules: [any StrictDispenseEstimateRule]

        init(rules: [any StrictDispenseEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictDispenseEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictDispenseEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictDispenseEstimate]) -> [String: [String]] {
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

    static func defaultStrictDispenseEstimateValidator() -> StrictDispenseEstimateValidator {
        return StrictDispenseEstimateValidator(
            rules: [
                StrictDispenseEstimateExpiresAtRangeRule(min: 16, max: 64),
                StrictDispenseEstimateCodeLengthRule(maxLength: 1000),
                StrictDispenseEstimateAllowedNameRule(allowed: ["rolling", "global", "primary"]),
            ]
        )
    }
}
