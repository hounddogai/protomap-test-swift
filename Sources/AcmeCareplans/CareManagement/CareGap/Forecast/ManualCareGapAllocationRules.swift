import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual care gap allocation must pass. Check returns its problems, or none.
    protocol ManualCareGapAllocationRule {
        func check(_ item: ManualCareGapAllocation) -> [String]
    }

    final class ManualCareGapAllocationTitleLengthRule: ManualCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapAllocationCodeLengthRule: ManualCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapAllocationCopayRangeRule: ManualCareGapAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCareGapAllocation) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualCareGapAllocationCodePrefixRule: ManualCareGapAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualCareGapAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualCareGapAllocationSpecialtyLengthRule: ManualCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareGapAllocation) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareGapAllocationRequiredSpecialtyRule: ManualCareGapAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareGapAllocation) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual care gap allocation.
    final class ManualCareGapAllocationValidator {
        var rules: [any ManualCareGapAllocationRule]

        init(rules: [any ManualCareGapAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareGapAllocation) -> [String] {
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

        func requireValid(_ item: ManualCareGapAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareGapAllocation]) -> [String: [String]] {
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

    static func defaultManualCareGapAllocationValidator() -> ManualCareGapAllocationValidator {
        return ManualCareGapAllocationValidator(
            rules: [
                ManualCareGapAllocationTitleLengthRule(maxLength: 3600),
                ManualCareGapAllocationCodeLengthRule(maxLength: 64),
                ManualCareGapAllocationCopayRangeRule(min: 2.3, max: 1472.8),
                ManualCareGapAllocationCodePrefixRule(prefix: "X"),
                ManualCareGapAllocationSpecialtyLengthRule(maxLength: 1000),
                ManualCareGapAllocationRequiredSpecialtyRule(message: "manual care gap allocation needs a value"),
            ]
        )
    }
}
