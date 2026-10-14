import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense threshold must pass. Check returns its problems, or none.
    protocol DispenseThresholdRule {
        func check(_ item: DispenseThreshold) -> [String]
    }

    final class DispenseThresholdRetriesRangeRule: DispenseThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseThreshold) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseThresholdRequiredSourceRule: DispenseThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseThreshold) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseThresholdAllowedCodeRule: DispenseThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense threshold.
    final class DispenseThresholdValidator {
        var rules: [any DispenseThresholdRule]

        init(rules: [any DispenseThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseThreshold]) -> [String: [String]] {
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

    static func defaultDispenseThresholdValidator() -> DispenseThresholdValidator {
        return DispenseThresholdValidator(
            rules: [
                DispenseThresholdRetriesRangeRule(min: 3600, max: 86400),
                DispenseThresholdRequiredSourceRule(message: "dispense threshold needs an entry"),
                DispenseThresholdAllowedCodeRule(allowed: ["tiered"]),
            ]
        )
    }
}
