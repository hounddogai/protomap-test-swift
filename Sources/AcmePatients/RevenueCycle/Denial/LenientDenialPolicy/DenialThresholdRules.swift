import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial threshold must pass. Check returns its problems, or none.
    protocol DenialThresholdRule {
        func check(_ item: DenialThreshold) -> [String]
    }

    final class DenialThresholdVisitMinutesRangeRule: DenialThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialThreshold) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialThresholdCodeLengthRule: DenialThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialThresholdCreatedAtRangeRule: DenialThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialThreshold) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial threshold.
    final class DenialThresholdValidator {
        var rules: [any DenialThresholdRule]

        init(rules: [any DenialThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialThreshold) -> [String] {
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

        func requireValid(_ item: DenialThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialThreshold]) -> [String: [String]] {
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

    static func defaultDenialThresholdValidator() -> DenialThresholdValidator {
        return DenialThresholdValidator(
            rules: [
                DenialThresholdVisitMinutesRangeRule(min: 16, max: 80),
                DenialThresholdCodeLengthRule(maxLength: 86400),
                DenialThresholdCreatedAtRangeRule(min: 16, max: 80),
            ]
        )
    }
}
