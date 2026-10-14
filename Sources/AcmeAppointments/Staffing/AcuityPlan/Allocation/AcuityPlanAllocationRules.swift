import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan allocation must pass. Check returns its problems, or none.
    protocol AcuityPlanAllocationRule {
        func check(_ item: AcuityPlanAllocation) -> [String]
    }

    final class AcuityPlanAllocationRequiredTitleRule: AcuityPlanAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanAllocationTitleLengthRule: AcuityPlanAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanAllocationAllowedCodeRule: AcuityPlanAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class AcuityPlanAllocationRequiredProcedureCodeRule: AcuityPlanAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanAllocation) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan allocation.
    final class AcuityPlanAllocationValidator {
        var rules: [any AcuityPlanAllocationRule]

        init(rules: [any AcuityPlanAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanAllocation) -> [String] {
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

        func requireValid(_ item: AcuityPlanAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanAllocation]) -> [String: [String]] {
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

    static func defaultAcuityPlanAllocationValidator() -> AcuityPlanAllocationValidator {
        return AcuityPlanAllocationValidator(
            rules: [
                AcuityPlanAllocationRequiredTitleRule(message: "acuity plan allocation needs this field"),
                AcuityPlanAllocationTitleLengthRule(maxLength: 3600),
                AcuityPlanAllocationAllowedCodeRule(allowed: ["batched", "global"]),
                AcuityPlanAllocationRequiredProcedureCodeRule(message: "acuity plan allocation needs a value"),
            ]
        )
    }
}
