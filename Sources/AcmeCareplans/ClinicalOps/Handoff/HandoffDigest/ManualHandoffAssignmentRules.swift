import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual handoff assignment must pass. Check returns its problems, or none.
    protocol ManualHandoffAssignmentRule {
        func check(_ item: ManualHandoffAssignment) -> [String]
    }

    final class ManualHandoffAssignmentChannelLengthRule: ManualHandoffAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualHandoffAssignment) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualHandoffAssignmentNameLengthRule: ManualHandoffAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualHandoffAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualHandoffAssignmentAllowedCodeRule: ManualHandoffAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualHandoffAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class ManualHandoffAssignmentRequiredNameRule: ManualHandoffAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualHandoffAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualHandoffAssignmentCodePrefixRule: ManualHandoffAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualHandoffAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualHandoffAssignmentExpiresAtRangeRule: ManualHandoffAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualHandoffAssignment) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual handoff assignment.
    final class ManualHandoffAssignmentValidator {
        var rules: [any ManualHandoffAssignmentRule]

        init(rules: [any ManualHandoffAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualHandoffAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualHandoffAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualHandoffAssignment]) -> [String: [String]] {
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

    static func defaultManualHandoffAssignmentValidator() -> ManualHandoffAssignmentValidator {
        return ManualHandoffAssignmentValidator(
            rules: [
                ManualHandoffAssignmentChannelLengthRule(maxLength: 120),
                ManualHandoffAssignmentNameLengthRule(maxLength: 80),
                ManualHandoffAssignmentAllowedCodeRule(allowed: []),
                ManualHandoffAssignmentRequiredNameRule(message: "manual handoff assignment needs a value"),
                ManualHandoffAssignmentCodePrefixRule(prefix: "REF"),
                ManualHandoffAssignmentExpiresAtRangeRule(min: 64, max: 255),
            ]
        )
    }
}
