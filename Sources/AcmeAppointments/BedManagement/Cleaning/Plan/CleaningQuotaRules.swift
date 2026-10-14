import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning quota must pass. Check returns its problems, or none.
    protocol CleaningQuotaRule {
        func check(_ item: CleaningQuota) -> [String]
    }

    final class CleaningQuotaRequiredLabelRule: CleaningQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningQuotaWindowDaysRangeRule: CleaningQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningQuota) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CleaningQuotaRequiredCodeRule: CleaningQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning quota.
    final class CleaningQuotaValidator {
        var rules: [any CleaningQuotaRule]

        init(rules: [any CleaningQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningQuota]) -> [String: [String]] {
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

    static func defaultCleaningQuotaValidator() -> CleaningQuotaValidator {
        return CleaningQuotaValidator(
            rules: [
                CleaningQuotaRequiredLabelRule(message: "cleaning quota needs a value"),
                CleaningQuotaWindowDaysRangeRule(min: 64, max: 255),
                CleaningQuotaRequiredCodeRule(message: "cleaning quota needs a value"),
            ]
        )
    }
}
