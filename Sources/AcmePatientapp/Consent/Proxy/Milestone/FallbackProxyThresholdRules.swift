import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback proxy threshold must pass. Check returns its problems, or none.
    protocol FallbackProxyThresholdRule {
        func check(_ item: FallbackProxyThreshold) -> [String]
    }

    final class FallbackProxyThresholdRequiredCodeRule: FallbackProxyThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackProxyThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackProxyThresholdCodeLengthRule: FallbackProxyThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackProxyThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackProxyThresholdNameLengthRule: FallbackProxyThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackProxyThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackProxyThresholdRequiredFacilityRule: FallbackProxyThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackProxyThreshold) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackProxyThresholdLimitRangeRule: FallbackProxyThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackProxyThreshold) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback proxy threshold.
    final class FallbackProxyThresholdValidator {
        var rules: [any FallbackProxyThresholdRule]

        init(rules: [any FallbackProxyThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackProxyThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackProxyThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackProxyThreshold]) -> [String: [String]] {
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

    static func defaultFallbackProxyThresholdValidator() -> FallbackProxyThresholdValidator {
        return FallbackProxyThresholdValidator(
            rules: [
                FallbackProxyThresholdRequiredCodeRule(message: "fallback proxy threshold needs this field"),
                FallbackProxyThresholdCodeLengthRule(maxLength: 255),
                FallbackProxyThresholdNameLengthRule(maxLength: 80),
                FallbackProxyThresholdRequiredFacilityRule(message: "fallback proxy threshold needs a value"),
                FallbackProxyThresholdLimitRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
