import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge allocation must pass. Check returns its problems, or none.
    protocol ChargeAllocationRule {
        func check(_ item: ChargeAllocation) -> [String]
    }

    final class ChargeAllocationRequiredClinicianIDRule: ChargeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeAllocation) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeAllocationClinicianIDLengthRule: ChargeAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeAllocation) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeAllocationCodePrefixRule: ChargeAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeAllocationCodeLengthRule: ChargeAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeAllocationAttemptsRangeRule: ChargeAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeAllocation) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeAllocationRequiredCodeRule: ChargeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge allocation.
    final class ChargeAllocationValidator {
        var rules: [any ChargeAllocationRule]

        init(rules: [any ChargeAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeAllocation) -> [String] {
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

        func requireValid(_ item: ChargeAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeAllocation]) -> [String: [String]] {
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

    static func defaultChargeAllocationValidator() -> ChargeAllocationValidator {
        return ChargeAllocationValidator(
            rules: [
                ChargeAllocationRequiredClinicianIDRule(message: "charge allocation needs this field"),
                ChargeAllocationClinicianIDLengthRule(maxLength: 16),
                ChargeAllocationCodePrefixRule(prefix: "ACM"),
                ChargeAllocationCodeLengthRule(maxLength: 64),
                ChargeAllocationAttemptsRangeRule(min: 1000, max: 86400),
                ChargeAllocationRequiredCodeRule(message: "charge allocation needs this field"),
            ]
        )
    }
}
