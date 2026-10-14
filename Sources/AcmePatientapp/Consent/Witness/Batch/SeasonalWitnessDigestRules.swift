import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal witness digest must pass. Check returns its problems, or none.
    protocol SeasonalWitnessDigestRule {
        func check(_ item: SeasonalWitnessDigest) -> [String]
    }

    final class SeasonalWitnessDigestAllowedUnitRule: SeasonalWitnessDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalWitnessDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalWitnessDigestAmountRangeRule: SeasonalWitnessDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalWitnessDigest) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalWitnessDigestCodeLengthRule: SeasonalWitnessDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWitnessDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWitnessDigestApprovedGuardRule: SeasonalWitnessDigestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SeasonalWitnessDigest) -> [String] {
            if item.approved && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal witness digest.
    final class SeasonalWitnessDigestValidator {
        var rules: [any SeasonalWitnessDigestRule]

        init(rules: [any SeasonalWitnessDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalWitnessDigest) -> [String] {
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

        func requireValid(_ item: SeasonalWitnessDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalWitnessDigest]) -> [String: [String]] {
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

    static func defaultSeasonalWitnessDigestValidator() -> SeasonalWitnessDigestValidator {
        return SeasonalWitnessDigestValidator(
            rules: [
                SeasonalWitnessDigestAllowedUnitRule(allowed: ["primary"]),
                SeasonalWitnessDigestAmountRangeRule(min: 5.9, max: 2426.2),
                SeasonalWitnessDigestCodeLengthRule(maxLength: 255),
                SeasonalWitnessDigestApprovedGuardRule(limit: 6.8),
            ]
        )
    }
}
