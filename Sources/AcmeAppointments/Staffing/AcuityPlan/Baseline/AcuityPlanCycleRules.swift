import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan cycle must pass. Check returns its problems, or none.
    protocol AcuityPlanCycleRule {
        func check(_ item: AcuityPlanCycle) -> [String]
    }

    final class AcuityPlanCycleRequiredLocaleRule: AcuityPlanCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanCycle) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanCycleRequiredNameRule: AcuityPlanCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanCycleCodeLengthRule: AcuityPlanCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan cycle.
    final class AcuityPlanCycleValidator {
        var rules: [any AcuityPlanCycleRule]

        init(rules: [any AcuityPlanCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanCycle) -> [String] {
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

        func requireValid(_ item: AcuityPlanCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanCycle]) -> [String: [String]] {
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

    static func defaultAcuityPlanCycleValidator() -> AcuityPlanCycleValidator {
        return AcuityPlanCycleValidator(
            rules: [
                AcuityPlanCycleRequiredLocaleRule(message: "acuity plan cycle needs this field"),
                AcuityPlanCycleRequiredNameRule(message: "acuity plan cycle needs an entry"),
                AcuityPlanCycleCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
