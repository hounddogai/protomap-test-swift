import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial audit must pass. Check returns its problems, or none.
    protocol DenialAuditRule {
        func check(_ item: DenialAudit) -> [String]
    }

    final class DenialAuditQuantityRangeRule: DenialAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialAudit) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialAuditVersionRangeRule: DenialAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialAudit) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialAuditNotesLengthRule: DenialAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAudit) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialAuditTitleLengthRule: DenialAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialAuditCodeLengthRule: DenialAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial audit.
    final class DenialAuditValidator {
        var rules: [any DenialAuditRule]

        init(rules: [any DenialAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialAudit) -> [String] {
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

        func requireValid(_ item: DenialAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialAudit]) -> [String: [String]] {
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

    static func defaultDenialAuditValidator() -> DenialAuditValidator {
        return DenialAuditValidator(
            rules: [
                DenialAuditQuantityRangeRule(min: 1000, max: 3600),
                DenialAuditVersionRangeRule(min: 80, max: 86400),
                DenialAuditNotesLengthRule(maxLength: 32),
                DenialAuditTitleLengthRule(maxLength: 3600),
                DenialAuditCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
