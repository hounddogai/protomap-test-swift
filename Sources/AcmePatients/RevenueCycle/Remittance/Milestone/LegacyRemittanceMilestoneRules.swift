import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy remittance milestone must pass. Check returns its problems, or none.
    protocol LegacyRemittanceMilestoneRule {
        func check(_ item: LegacyRemittanceMilestone) -> [String]
    }

    final class LegacyRemittanceMilestoneRequiredProcedureCodeRule: LegacyRemittanceMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRemittanceMilestone) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRemittanceMilestoneNameLengthRule: LegacyRemittanceMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRemittanceMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRemittanceMilestoneDiagnosisCodeLengthRule: LegacyRemittanceMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRemittanceMilestone) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy remittance milestone.
    final class LegacyRemittanceMilestoneValidator {
        var rules: [any LegacyRemittanceMilestoneRule]

        init(rules: [any LegacyRemittanceMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRemittanceMilestone) -> [String] {
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

        func requireValid(_ item: LegacyRemittanceMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRemittanceMilestone]) -> [String: [String]] {
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

    static func defaultLegacyRemittanceMilestoneValidator() -> LegacyRemittanceMilestoneValidator {
        return LegacyRemittanceMilestoneValidator(
            rules: [
                LegacyRemittanceMilestoneRequiredProcedureCodeRule(
                    message: "legacy remittance milestone needs a value"
                ),
                LegacyRemittanceMilestoneNameLengthRule(maxLength: 3600),
                LegacyRemittanceMilestoneDiagnosisCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
