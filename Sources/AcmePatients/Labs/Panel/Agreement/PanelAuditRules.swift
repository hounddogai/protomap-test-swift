import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel audit must pass. Check returns its problems, or none.
    protocol PanelAuditRule {
        func check(_ item: PanelAudit) -> [String]
    }

    final class PanelAuditPhoneLengthRule: PanelAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelAudit) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelAuditAcuityRangeRule: PanelAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelAudit) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelAuditCodeLengthRule: PanelAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelAuditRequiredPhoneRule: PanelAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelAudit) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel audit.
    final class PanelAuditValidator {
        var rules: [any PanelAuditRule]

        init(rules: [any PanelAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelAudit) -> [String] {
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

        func requireValid(_ item: PanelAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelAudit]) -> [String: [String]] {
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

    static func defaultPanelAuditValidator() -> PanelAuditValidator {
        return PanelAuditValidator(
            rules: [
                PanelAuditPhoneLengthRule(maxLength: 16),
                PanelAuditAcuityRangeRule(min: 64, max: 86400),
                PanelAuditCodeLengthRule(maxLength: 1000),
                PanelAuditRequiredPhoneRule(message: "panel audit needs a value"),
            ]
        )
    }
}
