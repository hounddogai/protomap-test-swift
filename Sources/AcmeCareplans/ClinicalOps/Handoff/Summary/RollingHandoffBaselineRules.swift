import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling handoff baseline must pass. Check returns its problems, or none.
    protocol RollingHandoffBaselineRule {
        func check(_ item: RollingHandoffBaseline) -> [String]
    }

    final class RollingHandoffBaselineRetriesRangeRule: RollingHandoffBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingHandoffBaseline) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingHandoffBaselineExternalRefLengthRule: RollingHandoffBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingHandoffBaseline) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingHandoffBaselineRequiredCodeRule: RollingHandoffBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingHandoffBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingHandoffBaselineCapacityRangeRule: RollingHandoffBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingHandoffBaseline) -> [String] {
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

    /// Runs every rule of a rolling handoff baseline.
    final class RollingHandoffBaselineValidator {
        var rules: [any RollingHandoffBaselineRule]

        init(rules: [any RollingHandoffBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingHandoffBaseline) -> [String] {
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

        func requireValid(_ item: RollingHandoffBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingHandoffBaseline]) -> [String: [String]] {
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

    static func defaultRollingHandoffBaselineValidator() -> RollingHandoffBaselineValidator {
        return RollingHandoffBaselineValidator(
            rules: [
                RollingHandoffBaselineRetriesRangeRule(min: 64, max: 86400),
                RollingHandoffBaselineExternalRefLengthRule(maxLength: 64),
                RollingHandoffBaselineRequiredCodeRule(message: "rolling handoff baseline needs an entry"),
                RollingHandoffBaselineCapacityRangeRule(min: 64, max: 80),
            ]
        )
    }
}
