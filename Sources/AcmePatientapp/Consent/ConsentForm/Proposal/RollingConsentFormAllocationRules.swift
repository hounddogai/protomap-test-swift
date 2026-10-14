import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling consent form allocation must pass. Check returns its problems, or none.
    protocol RollingConsentFormAllocationRule {
        func check(_ item: RollingConsentFormAllocation) -> [String]
    }

    final class RollingConsentFormAllocationRequiredCodeRule: RollingConsentFormAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormAllocationRequiredNotesRule: RollingConsentFormAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormAllocation) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormAllocationRequiredLabelRule: RollingConsentFormAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormAllocationRevisionRangeRule: RollingConsentFormAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingConsentFormAllocation) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingConsentFormAllocationNotesLengthRule: RollingConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingConsentFormAllocation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingConsentFormAllocationCodePrefixRule: RollingConsentFormAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingConsentFormAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling consent form allocation.
    final class RollingConsentFormAllocationValidator {
        var rules: [any RollingConsentFormAllocationRule]

        init(rules: [any RollingConsentFormAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingConsentFormAllocation) -> [String] {
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

        func requireValid(_ item: RollingConsentFormAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingConsentFormAllocation]) -> [String: [String]] {
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

    static func defaultRollingConsentFormAllocationValidator() -> RollingConsentFormAllocationValidator {
        return RollingConsentFormAllocationValidator(
            rules: [
                RollingConsentFormAllocationRequiredCodeRule(
                    message: "rolling consent form allocation needs an entry"
                ),
                RollingConsentFormAllocationRequiredNotesRule(
                    message: "rolling consent form allocation needs a value"
                ),
                RollingConsentFormAllocationRequiredLabelRule(
                    message: "rolling consent form allocation needs an entry"
                ),
                RollingConsentFormAllocationRevisionRangeRule(min: 3600, max: 86400),
                RollingConsentFormAllocationNotesLengthRule(maxLength: 1000),
                RollingConsentFormAllocationCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
