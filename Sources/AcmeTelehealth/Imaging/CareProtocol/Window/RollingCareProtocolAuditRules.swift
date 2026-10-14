import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling care protocol audit must pass. Check returns its problems, or none.
    protocol RollingCareProtocolAuditRule {
        func check(_ item: RollingCareProtocolAudit) -> [String]
    }

    final class RollingCareProtocolAuditChecksumLengthRule: RollingCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolAudit) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolAuditMinimumRangeRule: RollingCareProtocolAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolAudit) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCareProtocolAuditLabelLengthRule: RollingCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolAudit) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolAuditCopayRangeRule: RollingCareProtocolAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolAudit) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCareProtocolAuditPhoneLengthRule: RollingCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolAudit) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care protocol audit.
    final class RollingCareProtocolAuditValidator {
        var rules: [any RollingCareProtocolAuditRule]

        init(rules: [any RollingCareProtocolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareProtocolAudit) -> [String] {
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

        func requireValid(_ item: RollingCareProtocolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareProtocolAudit]) -> [String: [String]] {
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

    static func defaultRollingCareProtocolAuditValidator() -> RollingCareProtocolAuditValidator {
        return RollingCareProtocolAuditValidator(
            rules: [
                RollingCareProtocolAuditChecksumLengthRule(maxLength: 255),
                RollingCareProtocolAuditMinimumRangeRule(min: 3.0, max: 1602.9),
                RollingCareProtocolAuditLabelLengthRule(maxLength: 80),
                RollingCareProtocolAuditCopayRangeRule(min: 4.2, max: 1081.5),
                RollingCareProtocolAuditPhoneLengthRule(maxLength: 120),
            ]
        )
    }
}
