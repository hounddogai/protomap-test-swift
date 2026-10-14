import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall audit must pass. Check returns its problems, or none.
    protocol RecallAuditRule {
        func check(_ item: RecallAudit) -> [String]
    }

    final class RecallAuditRefillsRangeRule: RecallAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallAudit) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallAuditPriorityRangeRule: RecallAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallAudit) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallAuditChecksumLengthRule: RecallAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallAudit) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall audit.
    final class RecallAuditValidator {
        var rules: [any RecallAuditRule]

        init(rules: [any RecallAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallAudit]) -> [String: [String]] {
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

    static func defaultRecallAuditValidator() -> RecallAuditValidator {
        return RecallAuditValidator(
            rules: [
                RecallAuditRefillsRangeRule(min: 16, max: 3600),
                RecallAuditPriorityRangeRule(min: 120, max: 120),
                RecallAuditChecksumLengthRule(maxLength: 3600),
            ]
        )
    }
}
