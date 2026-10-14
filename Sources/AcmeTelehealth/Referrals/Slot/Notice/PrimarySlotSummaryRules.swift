import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary slot summary must pass. Check returns its problems, or none.
    protocol PrimarySlotSummaryRule {
        func check(_ item: PrimarySlotSummary) -> [String]
    }

    final class PrimarySlotSummaryTitleLengthRule: PrimarySlotSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySlotSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySlotSummaryAllowedCodeRule: PrimarySlotSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimarySlotSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class PrimarySlotSummaryRequiredTitleRule: PrimarySlotSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySlotSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySlotSummaryRequiredCodeRule: PrimarySlotSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySlotSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySlotSummaryAmountRangeRule: PrimarySlotSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySlotSummary) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary slot summary.
    final class PrimarySlotSummaryValidator {
        var rules: [any PrimarySlotSummaryRule]

        init(rules: [any PrimarySlotSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySlotSummary) -> [String] {
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

        func requireValid(_ item: PrimarySlotSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySlotSummary]) -> [String: [String]] {
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

    static func defaultPrimarySlotSummaryValidator() -> PrimarySlotSummaryValidator {
        return PrimarySlotSummaryValidator(
            rules: [
                PrimarySlotSummaryTitleLengthRule(maxLength: 64),
                PrimarySlotSummaryAllowedCodeRule(allowed: ["strict", "batched", "pending"]),
                PrimarySlotSummaryRequiredTitleRule(message: "primary slot summary needs this field"),
                PrimarySlotSummaryRequiredCodeRule(message: "primary slot summary needs this field"),
                PrimarySlotSummaryAmountRangeRule(min: 7.2, max: 3654.0),
            ]
        )
    }
}
