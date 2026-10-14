import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered read quota must pass. Check returns its problems, or none.
    protocol TieredReadQuotaRule {
        func check(_ item: TieredReadQuota) -> [String]
    }

    final class TieredReadQuotaRequiredTitleRule: TieredReadQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadQuotaScoreRangeRule: TieredReadQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReadQuota) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredReadQuotaStartsAtRangeRule: TieredReadQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReadQuota) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredReadQuotaRequiredCodeRule: TieredReadQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadQuotaEndsAtRangeRule: TieredReadQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReadQuota) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered read quota.
    final class TieredReadQuotaValidator {
        var rules: [any TieredReadQuotaRule]

        init(rules: [any TieredReadQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReadQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredReadQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReadQuota]) -> [String: [String]] {
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

    static func defaultTieredReadQuotaValidator() -> TieredReadQuotaValidator {
        return TieredReadQuotaValidator(
            rules: [
                TieredReadQuotaRequiredTitleRule(message: "tiered read quota needs a value"),
                TieredReadQuotaScoreRangeRule(min: 9.6, max: 131.2),
                TieredReadQuotaStartsAtRangeRule(min: 32, max: 255),
                TieredReadQuotaRequiredCodeRule(message: "tiered read quota needs a value"),
                TieredReadQuotaEndsAtRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
