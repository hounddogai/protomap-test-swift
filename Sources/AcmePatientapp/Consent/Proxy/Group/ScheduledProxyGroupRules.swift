import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled proxy group must pass. Check returns its problems, or none.
    protocol ScheduledProxyGroupRule {
        func check(_ item: ScheduledProxyGroup) -> [String]
    }

    final class ScheduledProxyGroupRequiredLabelRule: ScheduledProxyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledProxyGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledProxyGroupPatientRefLengthRule: ScheduledProxyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledProxyGroup) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledProxyGroupClinicianIDLengthRule: ScheduledProxyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledProxyGroup) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledProxyGroupBatchSizeRangeRule: ScheduledProxyGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledProxyGroup) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledProxyGroupRequiredCodeRule: ScheduledProxyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledProxyGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledProxyGroupAllowedLabelRule: ScheduledProxyGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledProxyGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled proxy group.
    final class ScheduledProxyGroupValidator {
        var rules: [any ScheduledProxyGroupRule]

        init(rules: [any ScheduledProxyGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledProxyGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledProxyGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledProxyGroup]) -> [String: [String]] {
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

    static func defaultScheduledProxyGroupValidator() -> ScheduledProxyGroupValidator {
        return ScheduledProxyGroupValidator(
            rules: [
                ScheduledProxyGroupRequiredLabelRule(message: "scheduled proxy group needs an entry"),
                ScheduledProxyGroupPatientRefLengthRule(maxLength: 86400),
                ScheduledProxyGroupClinicianIDLengthRule(maxLength: 80),
                ScheduledProxyGroupBatchSizeRangeRule(min: 16, max: 1000),
                ScheduledProxyGroupRequiredCodeRule(message: "scheduled proxy group needs a value"),
                ScheduledProxyGroupAllowedLabelRule(allowed: ["legacy", "batched"]),
            ]
        )
    }
}
