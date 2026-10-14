import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending handoff baseline must pass. Check returns its problems, or none.
    protocol PendingHandoffBaselineRule {
        func check(_ item: PendingHandoffBaseline) -> [String]
    }

    final class PendingHandoffBaselineRequiredDiagnosisCodeRule: PendingHandoffBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingHandoffBaseline) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingHandoffBaselineAllowedDiagnosisCodeRule: PendingHandoffBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingHandoffBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is blocked"]
            }
            return []
        }
    }

    final class PendingHandoffBaselinePriorityRangeRule: PendingHandoffBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffBaseline) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingHandoffBaselineDiagnosisCodeLengthRule: PendingHandoffBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingHandoffBaseline) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending handoff baseline.
    final class PendingHandoffBaselineValidator {
        var rules: [any PendingHandoffBaselineRule]

        init(rules: [any PendingHandoffBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingHandoffBaseline) -> [String] {
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

        func requireValid(_ item: PendingHandoffBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingHandoffBaseline]) -> [String: [String]] {
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

    static func defaultPendingHandoffBaselineValidator() -> PendingHandoffBaselineValidator {
        return PendingHandoffBaselineValidator(
            rules: [
                PendingHandoffBaselineRequiredDiagnosisCodeRule(message: "pending handoff baseline needs this field"),
                PendingHandoffBaselineAllowedDiagnosisCodeRule(allowed: ["global", "batched"]),
                PendingHandoffBaselinePriorityRangeRule(min: 120, max: 255),
                PendingHandoffBaselineDiagnosisCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
