import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling inventory draft must pass. Check returns its problems, or none.
    protocol RollingInventoryDraftRule {
        func check(_ item: RollingInventoryDraft) -> [String]
    }

    final class RollingInventoryDraftWeightRangeRule: RollingInventoryDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInventoryDraft) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingInventoryDraftRequiredCodeRule: RollingInventoryDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingInventoryDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingInventoryDraftEndsAtRangeRule: RollingInventoryDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInventoryDraft) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingInventoryDraftLabelLengthRule: RollingInventoryDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingInventoryDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingInventoryDraftCodeLengthRule: RollingInventoryDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingInventoryDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingInventoryDraftCodePrefixRule: RollingInventoryDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingInventoryDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling inventory draft.
    final class RollingInventoryDraftValidator {
        var rules: [any RollingInventoryDraftRule]

        init(rules: [any RollingInventoryDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingInventoryDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingInventoryDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingInventoryDraft]) -> [String: [String]] {
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

    static func defaultRollingInventoryDraftValidator() -> RollingInventoryDraftValidator {
        return RollingInventoryDraftValidator(
            rules: [
                RollingInventoryDraftWeightRangeRule(min: 2.1, max: 4277.3),
                RollingInventoryDraftRequiredCodeRule(message: "rolling inventory draft needs this field"),
                RollingInventoryDraftEndsAtRangeRule(min: 64, max: 3600),
                RollingInventoryDraftLabelLengthRule(maxLength: 64),
                RollingInventoryDraftCodeLengthRule(maxLength: 86400),
                RollingInventoryDraftCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
