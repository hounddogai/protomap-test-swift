import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan request must pass. Check returns its problems, or none.
    protocol DischargePlanRequestRule {
        func check(_ item: DischargePlanRequest) -> [String]
    }

    final class DischargePlanRequestCodePrefixRule: DischargePlanRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanRequestBudgetRangeRule: DischargePlanRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanRequest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanRequestAllowedClinicianIDRule: DischargePlanRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan request.
    final class DischargePlanRequestValidator {
        var rules: [any DischargePlanRequestRule]

        init(rules: [any DischargePlanRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanRequest) -> [String] {
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

        func requireValid(_ item: DischargePlanRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanRequest]) -> [String: [String]] {
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

    static func defaultDischargePlanRequestValidator() -> DischargePlanRequestValidator {
        return DischargePlanRequestValidator(
            rules: [
                DischargePlanRequestCodePrefixRule(prefix: "X"),
                DischargePlanRequestBudgetRangeRule(min: 6.0, max: 883.2),
                DischargePlanRequestAllowedClinicianIDRule(allowed: ["pending"]),
            ]
        )
    }
}
