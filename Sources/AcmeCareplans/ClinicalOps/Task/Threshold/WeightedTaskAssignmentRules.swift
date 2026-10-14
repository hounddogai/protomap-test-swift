import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted task assignment must pass. Check returns its problems, or none.
    protocol WeightedTaskAssignmentRule {
        func check(_ item: WeightedTaskAssignment) -> [String]
    }

    final class WeightedTaskAssignmentRequiredChecksumRule: WeightedTaskAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskAssignment) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTaskAssignmentAllowedLabelRule: WeightedTaskAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedTaskAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class WeightedTaskAssignmentCodeLengthRule: WeightedTaskAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTaskAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedTaskAssignmentRequiredCodeRule: WeightedTaskAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTaskAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTaskAssignmentCodePrefixRule: WeightedTaskAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedTaskAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted task assignment.
    final class WeightedTaskAssignmentValidator {
        var rules: [any WeightedTaskAssignmentRule]

        init(rules: [any WeightedTaskAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTaskAssignment) -> [String] {
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

        func requireValid(_ item: WeightedTaskAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTaskAssignment]) -> [String: [String]] {
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

    static func defaultWeightedTaskAssignmentValidator() -> WeightedTaskAssignmentValidator {
        return WeightedTaskAssignmentValidator(
            rules: [
                WeightedTaskAssignmentRequiredChecksumRule(message: "weighted task assignment needs an entry"),
                WeightedTaskAssignmentAllowedLabelRule(allowed: ["manual"]),
                WeightedTaskAssignmentCodeLengthRule(maxLength: 32),
                WeightedTaskAssignmentRequiredCodeRule(message: "weighted task assignment needs this field"),
                WeightedTaskAssignmentCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
