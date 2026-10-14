import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier allocation must pass. Check returns its problems, or none.
    protocol CourierAllocationRule {
        func check(_ item: CourierAllocation) -> [String]
    }

    final class CourierAllocationContactEmailLengthRule: CourierAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierAllocation) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierAllocationDosageMgRangeRule: CourierAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierAllocation) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CourierAllocationRequiredCodeRule: CourierAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierAllocationCodePrefixRule: CourierAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier allocation.
    final class CourierAllocationValidator {
        var rules: [any CourierAllocationRule]

        init(rules: [any CourierAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierAllocation]) -> [String: [String]] {
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

    static func defaultCourierAllocationValidator() -> CourierAllocationValidator {
        return CourierAllocationValidator(
            rules: [
                CourierAllocationContactEmailLengthRule(maxLength: 255),
                CourierAllocationDosageMgRangeRule(min: 0.2, max: 2737.3),
                CourierAllocationRequiredCodeRule(message: "courier allocation needs this field"),
                CourierAllocationCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
