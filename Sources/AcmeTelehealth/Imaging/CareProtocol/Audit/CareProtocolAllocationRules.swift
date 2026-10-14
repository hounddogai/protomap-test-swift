import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol allocation must pass. Check returns its problems, or none.
    protocol CareProtocolAllocationRule {
        func check(_ item: CareProtocolAllocation) -> [String]
    }

    final class CareProtocolAllocationRequiredDescriptionRule: CareProtocolAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolAllocation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolAllocationCodePrefixRule: CareProtocolAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolAllocationDosageMgRangeRule: CareProtocolAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolAllocation) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolAllocationCodeLengthRule: CareProtocolAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolAllocationQuantityRangeRule: CareProtocolAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolAllocation) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol allocation.
    final class CareProtocolAllocationValidator {
        var rules: [any CareProtocolAllocationRule]

        init(rules: [any CareProtocolAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolAllocation) -> [String] {
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

        func requireValid(_ item: CareProtocolAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolAllocation]) -> [String: [String]] {
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

    static func defaultCareProtocolAllocationValidator() -> CareProtocolAllocationValidator {
        return CareProtocolAllocationValidator(
            rules: [
                CareProtocolAllocationRequiredDescriptionRule(message: "care protocol allocation needs a value"),
                CareProtocolAllocationCodePrefixRule(prefix: "X"),
                CareProtocolAllocationDosageMgRangeRule(min: 2.3, max: 2899.5),
                CareProtocolAllocationCodeLengthRule(maxLength: 86400),
                CareProtocolAllocationQuantityRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
