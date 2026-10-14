import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped panel audit must pass. Check returns its problems, or none.
    protocol CappedPanelAuditRule {
        func check(_ item: CappedPanelAudit) -> [String]
    }

    final class CappedPanelAuditDiscountRangeRule: CappedPanelAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedPanelAudit) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedPanelAuditCodePrefixRule: CappedPanelAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedPanelAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedPanelAuditRequiredLabelRule: CappedPanelAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPanelAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedPanelAuditAllowedCodeRule: CappedPanelAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedPanelAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a capped panel audit.
    final class CappedPanelAuditValidator {
        var rules: [any CappedPanelAuditRule]

        init(rules: [any CappedPanelAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedPanelAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedPanelAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedPanelAudit]) -> [String: [String]] {
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

    static func defaultCappedPanelAuditValidator() -> CappedPanelAuditValidator {
        return CappedPanelAuditValidator(
            rules: [
                CappedPanelAuditDiscountRangeRule(min: 10.0, max: 3559.9),
                CappedPanelAuditCodePrefixRule(prefix: "OPS"),
                CappedPanelAuditRequiredLabelRule(message: "capped panel audit needs a value"),
                CappedPanelAuditAllowedCodeRule(allowed: ["strict", "seasonal", "primary"]),
            ]
        )
    }
}
