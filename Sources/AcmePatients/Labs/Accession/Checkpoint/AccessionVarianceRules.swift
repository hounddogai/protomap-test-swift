import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession variance must pass. Check returns its problems, or none.
    protocol AccessionVarianceRule {
        func check(_ item: AccessionVariance) -> [String]
    }

    final class AccessionVarianceAllowedSpecialtyRule: AccessionVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is not allowed"]
            }
            return []
        }
    }

    final class AccessionVarianceEncounterIDLengthRule: AccessionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionVariance) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionVarianceCopayRangeRule: AccessionVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionVariance) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionVarianceSpecialtyLengthRule: AccessionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionVariance) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession variance.
    final class AccessionVarianceValidator {
        var rules: [any AccessionVarianceRule]

        init(rules: [any AccessionVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionVariance]) -> [String: [String]] {
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

    static func defaultAccessionVarianceValidator() -> AccessionVarianceValidator {
        return AccessionVarianceValidator(
            rules: [
                AccessionVarianceAllowedSpecialtyRule(allowed: ["seasonal", "lenient", "capped"]),
                AccessionVarianceEncounterIDLengthRule(maxLength: 120),
                AccessionVarianceCopayRangeRule(min: 6.9, max: 1782.7),
                AccessionVarianceSpecialtyLengthRule(maxLength: 3600),
            ]
        )
    }
}
