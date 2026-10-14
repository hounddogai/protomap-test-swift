import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending census allocation must pass. Check returns its problems, or none.
    protocol PendingCensusAllocationRule {
        func check(_ item: PendingCensusAllocation) -> [String]
    }

    final class PendingCensusAllocationRequiredAllergyRule: PendingCensusAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCensusAllocation) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCensusAllocationTitleLengthRule: PendingCensusAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCensusAllocationCodePrefixRule: PendingCensusAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCensusAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingCensusAllocationQuantityRangeRule: PendingCensusAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusAllocation) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCensusAllocationLocaleLengthRule: PendingCensusAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusAllocation) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCensusAllocationCodeLengthRule: PendingCensusAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending census allocation.
    final class PendingCensusAllocationValidator {
        var rules: [any PendingCensusAllocationRule]

        init(rules: [any PendingCensusAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCensusAllocation) -> [String] {
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

        func requireValid(_ item: PendingCensusAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCensusAllocation]) -> [String: [String]] {
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

    static func defaultPendingCensusAllocationValidator() -> PendingCensusAllocationValidator {
        return PendingCensusAllocationValidator(
            rules: [
                PendingCensusAllocationRequiredAllergyRule(message: "pending census allocation needs this field"),
                PendingCensusAllocationTitleLengthRule(maxLength: 1000),
                PendingCensusAllocationCodePrefixRule(prefix: "OPS"),
                PendingCensusAllocationQuantityRangeRule(min: 255, max: 86400),
                PendingCensusAllocationLocaleLengthRule(maxLength: 3600),
                PendingCensusAllocationCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
