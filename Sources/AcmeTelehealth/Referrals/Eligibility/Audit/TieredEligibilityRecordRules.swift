import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered eligibility record must pass. Check returns its problems, or none.
    protocol TieredEligibilityRecordRule {
        func check(_ item: TieredEligibilityRecord) -> [String]
    }

    final class TieredEligibilityRecordWindowDaysRangeRule: TieredEligibilityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredEligibilityRecord) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredEligibilityRecordCodePrefixRule: TieredEligibilityRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredEligibilityRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredEligibilityRecordAllowedTitleRule: TieredEligibilityRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredEligibilityRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class TieredEligibilityRecordBatchSizeRangeRule: TieredEligibilityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredEligibilityRecord) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered eligibility record.
    final class TieredEligibilityRecordValidator {
        var rules: [any TieredEligibilityRecordRule]

        init(rules: [any TieredEligibilityRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredEligibilityRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredEligibilityRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredEligibilityRecord]) -> [String: [String]] {
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

    static func defaultTieredEligibilityRecordValidator() -> TieredEligibilityRecordValidator {
        return TieredEligibilityRecordValidator(
            rules: [
                TieredEligibilityRecordWindowDaysRangeRule(min: 255, max: 3600),
                TieredEligibilityRecordCodePrefixRule(prefix: "Q"),
                TieredEligibilityRecordAllowedTitleRule(allowed: ["scheduled", "global"]),
                TieredEligibilityRecordBatchSizeRangeRule(min: 64, max: 120),
            ]
        )
    }
}
