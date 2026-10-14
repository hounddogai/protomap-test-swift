import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning audit must pass. Check returns its problems, or none.
    protocol CleaningAuditRule {
        func check(_ item: CleaningAudit) -> [String]
    }

    final class CleaningAuditCountryLengthRule: CleaningAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningAudit) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningAuditCodeLengthRule: CleaningAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningAuditCodePrefixRule: CleaningAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CleaningAuditRevisionRangeRule: CleaningAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningAudit) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningAuditRequiredCountryRule: CleaningAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningAudit) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningAuditFloorValueRangeRule: CleaningAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningAudit) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a cleaning audit.
    final class CleaningAuditValidator {
        var rules: [any CleaningAuditRule]

        init(rules: [any CleaningAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningAudit) -> [String] {
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

        func requireValid(_ item: CleaningAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningAudit]) -> [String: [String]] {
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

    static func defaultCleaningAuditValidator() -> CleaningAuditValidator {
        return CleaningAuditValidator(
            rules: [
                CleaningAuditCountryLengthRule(maxLength: 80),
                CleaningAuditCodeLengthRule(maxLength: 32),
                CleaningAuditCodePrefixRule(prefix: "REF"),
                CleaningAuditRevisionRangeRule(min: 64, max: 80),
                CleaningAuditRequiredCountryRule(message: "cleaning audit needs an entry"),
                CleaningAuditFloorValueRangeRule(min: 5.7, max: 1742.8),
            ]
        )
    }
}
