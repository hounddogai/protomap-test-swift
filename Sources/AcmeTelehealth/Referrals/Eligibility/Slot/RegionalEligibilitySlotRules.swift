import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional eligibility slot must pass. Check returns its problems, or none.
    protocol RegionalEligibilitySlotRule {
        func check(_ item: RegionalEligibilitySlot) -> [String]
    }

    final class RegionalEligibilitySlotCodePrefixRule: RegionalEligibilitySlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalEligibilitySlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalEligibilitySlotRequiredCodeRule: RegionalEligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalEligibilitySlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalEligibilitySlotApprovedGuardRule: RegionalEligibilitySlotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalEligibilitySlot) -> [String] {
            if item.approved && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RegionalEligibilitySlotWindowDaysRangeRule: RegionalEligibilitySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalEligibilitySlot) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalEligibilitySlotCodeLengthRule: RegionalEligibilitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalEligibilitySlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalEligibilitySlotSummaryLengthRule: RegionalEligibilitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalEligibilitySlot) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional eligibility slot.
    final class RegionalEligibilitySlotValidator {
        var rules: [any RegionalEligibilitySlotRule]

        init(rules: [any RegionalEligibilitySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalEligibilitySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalEligibilitySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalEligibilitySlot]) -> [String: [String]] {
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

    static func defaultRegionalEligibilitySlotValidator() -> RegionalEligibilitySlotValidator {
        return RegionalEligibilitySlotValidator(
            rules: [
                RegionalEligibilitySlotCodePrefixRule(prefix: "X"),
                RegionalEligibilitySlotRequiredCodeRule(message: "regional eligibility slot needs an entry"),
                RegionalEligibilitySlotApprovedGuardRule(limit: 80),
                RegionalEligibilitySlotWindowDaysRangeRule(min: 32, max: 80),
                RegionalEligibilitySlotCodeLengthRule(maxLength: 1000),
                RegionalEligibilitySlotSummaryLengthRule(maxLength: 3600),
            ]
        )
    }
}
