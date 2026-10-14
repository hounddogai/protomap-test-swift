import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted outreach allocation must pass. Check returns its problems, or none.
    protocol WeightedOutreachAllocationRule {
        func check(_ item: WeightedOutreachAllocation) -> [String]
    }

    final class WeightedOutreachAllocationPatientRefLengthRule: WeightedOutreachAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOutreachAllocation) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOutreachAllocationAllowedPatientRefRule: WeightedOutreachAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedOutreachAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is duplicated"]
            }
            return []
        }
    }

    final class WeightedOutreachAllocationSegmentLengthRule: WeightedOutreachAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOutreachAllocation) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOutreachAllocationRequiredCodeRule: WeightedOutreachAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedOutreachAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted outreach allocation.
    final class WeightedOutreachAllocationValidator {
        var rules: [any WeightedOutreachAllocationRule]

        init(rules: [any WeightedOutreachAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedOutreachAllocation) -> [String] {
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

        func requireValid(_ item: WeightedOutreachAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedOutreachAllocation]) -> [String: [String]] {
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

    static func defaultWeightedOutreachAllocationValidator() -> WeightedOutreachAllocationValidator {
        return WeightedOutreachAllocationValidator(
            rules: [
                WeightedOutreachAllocationPatientRefLengthRule(maxLength: 255),
                WeightedOutreachAllocationAllowedPatientRefRule(allowed: ["global", "pending"]),
                WeightedOutreachAllocationSegmentLengthRule(maxLength: 3600),
                WeightedOutreachAllocationRequiredCodeRule(message: "weighted outreach allocation needs this field"),
            ]
        )
    }
}
