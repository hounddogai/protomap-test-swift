import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach assignment must pass. Check returns its problems, or none.
    protocol OutreachAssignmentRule {
        func check(_ item: OutreachAssignment) -> [String]
    }

    final class OutreachAssignmentFacilityLengthRule: OutreachAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachAssignment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachAssignmentRequiredLabelRule: OutreachAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachAssignmentAllowedCodeRule: OutreachAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class OutreachAssignmentThresholdRangeRule: OutreachAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachAssignment) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachAssignmentCodePrefixRule: OutreachAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach assignment.
    final class OutreachAssignmentValidator {
        var rules: [any OutreachAssignmentRule]

        init(rules: [any OutreachAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachAssignment]) -> [String: [String]] {
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

    static func defaultOutreachAssignmentValidator() -> OutreachAssignmentValidator {
        return OutreachAssignmentValidator(
            rules: [
                OutreachAssignmentFacilityLengthRule(maxLength: 64),
                OutreachAssignmentRequiredLabelRule(message: "outreach assignment needs this field"),
                OutreachAssignmentAllowedCodeRule(allowed: ["batched", "seasonal"]),
                OutreachAssignmentThresholdRangeRule(min: 0.7, max: 134.8),
                OutreachAssignmentCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
