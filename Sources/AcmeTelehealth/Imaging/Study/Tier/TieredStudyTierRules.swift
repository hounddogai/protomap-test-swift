import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered study tier must pass. Check returns its problems, or none.
    protocol TieredStudyTierRule {
        func check(_ item: TieredStudyTier) -> [String]
    }

    final class TieredStudyTierQuantityRangeRule: TieredStudyTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredStudyTier) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredStudyTierPinnedGuardRule: TieredStudyTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredStudyTier) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class TieredStudyTierRequiredProcedureCodeRule: TieredStudyTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredStudyTier) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered study tier.
    final class TieredStudyTierValidator {
        var rules: [any TieredStudyTierRule]

        init(rules: [any TieredStudyTierRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredStudyTier) -> [String] {
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

        func requireValid(_ item: TieredStudyTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredStudyTier]) -> [String: [String]] {
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

    static func defaultTieredStudyTierValidator() -> TieredStudyTierValidator {
        return TieredStudyTierValidator(
            rules: [
                TieredStudyTierQuantityRangeRule(min: 64, max: 3600),
                TieredStudyTierPinnedGuardRule(limit: 80),
                TieredStudyTierRequiredProcedureCodeRule(message: "tiered study tier needs an entry"),
            ]
        )
    }
}
