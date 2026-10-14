import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped revocation score must pass. Check returns its problems, or none.
    protocol CappedRevocationScoreRule {
        func check(_ item: CappedRevocationScore) -> [String]
    }

    final class CappedRevocationScoreAllowedCodeRule: CappedRevocationScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedRevocationScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class CappedRevocationScoreCreatedAtRangeRule: CappedRevocationScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRevocationScore) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedRevocationScoreCopayRangeRule: CappedRevocationScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRevocationScore) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped revocation score.
    final class CappedRevocationScoreValidator {
        var rules: [any CappedRevocationScoreRule]

        init(rules: [any CappedRevocationScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRevocationScore) -> [String] {
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

        func requireValid(_ item: CappedRevocationScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRevocationScore]) -> [String: [String]] {
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

    static func defaultCappedRevocationScoreValidator() -> CappedRevocationScoreValidator {
        return CappedRevocationScoreValidator(
            rules: [
                CappedRevocationScoreAllowedCodeRule(allowed: ["default"]),
                CappedRevocationScoreCreatedAtRangeRule(min: 64, max: 86400),
                CappedRevocationScoreCopayRangeRule(min: 8.9, max: 2730.0),
            ]
        )
    }
}
