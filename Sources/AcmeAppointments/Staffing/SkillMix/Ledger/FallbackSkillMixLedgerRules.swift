import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback skill mix ledger must pass. Check returns its problems, or none.
    protocol FallbackSkillMixLedgerRule {
        func check(_ item: FallbackSkillMixLedger) -> [String]
    }

    final class FallbackSkillMixLedgerQuantityRangeRule: FallbackSkillMixLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSkillMixLedger) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackSkillMixLedgerTitleLengthRule: FallbackSkillMixLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSkillMixLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSkillMixLedgerCodePrefixRule: FallbackSkillMixLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackSkillMixLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackSkillMixLedgerRegionLengthRule: FallbackSkillMixLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSkillMixLedger) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSkillMixLedgerRequiredCodeRule: FallbackSkillMixLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackSkillMixLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackSkillMixLedgerDiscountRangeRule: FallbackSkillMixLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSkillMixLedger) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback skill mix ledger.
    final class FallbackSkillMixLedgerValidator {
        var rules: [any FallbackSkillMixLedgerRule]

        init(rules: [any FallbackSkillMixLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSkillMixLedger) -> [String] {
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

        func requireValid(_ item: FallbackSkillMixLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSkillMixLedger]) -> [String: [String]] {
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

    static func defaultFallbackSkillMixLedgerValidator() -> FallbackSkillMixLedgerValidator {
        return FallbackSkillMixLedgerValidator(
            rules: [
                FallbackSkillMixLedgerQuantityRangeRule(min: 120, max: 120),
                FallbackSkillMixLedgerTitleLengthRule(maxLength: 3600),
                FallbackSkillMixLedgerCodePrefixRule(prefix: "X"),
                FallbackSkillMixLedgerRegionLengthRule(maxLength: 86400),
                FallbackSkillMixLedgerRequiredCodeRule(message: "fallback skill mix ledger needs this field"),
                FallbackSkillMixLedgerDiscountRangeRule(min: 2.4, max: 1966.8),
            ]
        )
    }
}
