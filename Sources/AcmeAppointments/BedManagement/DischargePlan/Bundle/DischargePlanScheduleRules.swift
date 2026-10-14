import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan schedule must pass. Check returns its problems, or none.
    protocol DischargePlanScheduleRule {
        func check(_ item: DischargePlanSchedule) -> [String]
    }

    final class DischargePlanScheduleAllowedExternalRefRule: DischargePlanScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is missing"]
            }
            return []
        }
    }

    final class DischargePlanScheduleCodePrefixRule: DischargePlanScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanScheduleExternalRefLengthRule: DischargePlanScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanSchedule) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan schedule.
    final class DischargePlanScheduleValidator {
        var rules: [any DischargePlanScheduleRule]

        init(rules: [any DischargePlanScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanSchedule) -> [String] {
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

        func requireValid(_ item: DischargePlanSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanSchedule]) -> [String: [String]] {
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

    static func defaultDischargePlanScheduleValidator() -> DischargePlanScheduleValidator {
        return DischargePlanScheduleValidator(
            rules: [
                DischargePlanScheduleAllowedExternalRefRule(allowed: ["seasonal", "capped", "tiered"]),
                DischargePlanScheduleCodePrefixRule(prefix: "ACM"),
                DischargePlanScheduleExternalRefLengthRule(maxLength: 1000),
            ]
        )
    }
}
