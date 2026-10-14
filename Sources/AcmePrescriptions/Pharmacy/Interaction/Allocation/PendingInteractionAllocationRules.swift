import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending interaction allocation must pass. Check returns its problems, or none.
    protocol PendingInteractionAllocationRule {
        func check(_ item: PendingInteractionAllocation) -> [String]
    }

    final class PendingInteractionAllocationRequiredPatientRefRule: PendingInteractionAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingInteractionAllocation) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingInteractionAllocationPatientRefLengthRule: PendingInteractionAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingInteractionAllocation) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingInteractionAllocationCodePrefixRule: PendingInteractionAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingInteractionAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending interaction allocation.
    final class PendingInteractionAllocationValidator {
        var rules: [any PendingInteractionAllocationRule]

        init(rules: [any PendingInteractionAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingInteractionAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingInteractionAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingInteractionAllocation]) -> [String: [String]] {
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

    static func defaultPendingInteractionAllocationValidator() -> PendingInteractionAllocationValidator {
        return PendingInteractionAllocationValidator(
            rules: [
                PendingInteractionAllocationRequiredPatientRefRule(
                    message: "pending interaction allocation needs an entry"
                ),
                PendingInteractionAllocationPatientRefLengthRule(maxLength: 255),
                PendingInteractionAllocationCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
