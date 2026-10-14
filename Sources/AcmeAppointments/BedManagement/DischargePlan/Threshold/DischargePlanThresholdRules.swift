import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan threshold must pass. Check returns its problems, or none.
    protocol DischargePlanThresholdRule {
        func check(_ item: DischargePlanThreshold) -> [String]
    }

    final class DischargePlanThresholdAllowedCodeRule: DischargePlanThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class DischargePlanThresholdRequiredCodeRule: DischargePlanThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanThresholdSpecialtyLengthRule: DischargePlanThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanThreshold) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan threshold.
    final class DischargePlanThresholdValidator {
        var rules: [any DischargePlanThresholdRule]

        init(rules: [any DischargePlanThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanThreshold) -> [String] {
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

        func requireValid(_ item: DischargePlanThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanThreshold]) -> [String: [String]] {
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

    static func defaultDischargePlanThresholdValidator() -> DischargePlanThresholdValidator {
        return DischargePlanThresholdValidator(
            rules: [
                DischargePlanThresholdAllowedCodeRule(allowed: ["tiered", "legacy"]),
                DischargePlanThresholdRequiredCodeRule(message: "discharge plan threshold needs a value"),
                DischargePlanThresholdSpecialtyLengthRule(maxLength: 32),
            ]
        )
    }
}
