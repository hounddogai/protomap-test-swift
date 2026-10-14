import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance assignment must pass. Check returns its problems, or none.
    protocol RemittanceAssignmentRule {
        func check(_ item: RemittanceAssignment) -> [String]
    }

    final class RemittanceAssignmentRequiredNameRule: RemittanceAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceAssignmentCodePrefixRule: RemittanceAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceAssignmentRefillsRangeRule: RemittanceAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceAssignment) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceAssignmentAllergyLengthRule: RemittanceAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceAssignment) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance assignment.
    final class RemittanceAssignmentValidator {
        var rules: [any RemittanceAssignmentRule]

        init(rules: [any RemittanceAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceAssignment) -> [String] {
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

        func requireValid(_ item: RemittanceAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceAssignment]) -> [String: [String]] {
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

    static func defaultRemittanceAssignmentValidator() -> RemittanceAssignmentValidator {
        return RemittanceAssignmentValidator(
            rules: [
                RemittanceAssignmentRequiredNameRule(message: "remittance assignment needs this field"),
                RemittanceAssignmentCodePrefixRule(prefix: "Q"),
                RemittanceAssignmentRefillsRangeRule(min: 16, max: 3600),
                RemittanceAssignmentAllergyLengthRule(maxLength: 16),
            ]
        )
    }
}
