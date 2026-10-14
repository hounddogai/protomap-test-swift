import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense allocation must pass. Check returns its problems, or none.
    protocol DispenseAllocationRule {
        func check(_ item: DispenseAllocation) -> [String]
    }

    final class DispenseAllocationCodePrefixRule: DispenseAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseAllocationCodeLengthRule: DispenseAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseAllocationCapacityRangeRule: DispenseAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseAllocation) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseAllocationRequiredLabelRule: DispenseAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseAllocationAllowedChecksumRule: DispenseAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense allocation.
    final class DispenseAllocationValidator {
        var rules: [any DispenseAllocationRule]

        init(rules: [any DispenseAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseAllocation) -> [String] {
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

        func requireValid(_ item: DispenseAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseAllocation]) -> [String: [String]] {
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

    static func defaultDispenseAllocationValidator() -> DispenseAllocationValidator {
        return DispenseAllocationValidator(
            rules: [
                DispenseAllocationCodePrefixRule(prefix: "X"),
                DispenseAllocationCodeLengthRule(maxLength: 120),
                DispenseAllocationCapacityRangeRule(min: 64, max: 1000),
                DispenseAllocationRequiredLabelRule(message: "dispense allocation needs an entry"),
                DispenseAllocationAllowedChecksumRule(allowed: ["tiered"]),
            ]
        )
    }
}
