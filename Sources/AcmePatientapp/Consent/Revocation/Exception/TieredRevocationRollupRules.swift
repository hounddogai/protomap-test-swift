import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered revocation rollup must pass. Check returns its problems, or none.
    protocol TieredRevocationRollupRule {
        func check(_ item: TieredRevocationRollup) -> [String]
    }

    final class TieredRevocationRollupRequiredLabelRule: TieredRevocationRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRevocationRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRevocationRollupAcuityRangeRule: TieredRevocationRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRevocationRollup) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRevocationRollupAllergyLengthRule: TieredRevocationRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRevocationRollup) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRevocationRollupLabelLengthRule: TieredRevocationRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRevocationRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered revocation rollup.
    final class TieredRevocationRollupValidator {
        var rules: [any TieredRevocationRollupRule]

        init(rules: [any TieredRevocationRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRevocationRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRevocationRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRevocationRollup]) -> [String: [String]] {
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

    static func defaultTieredRevocationRollupValidator() -> TieredRevocationRollupValidator {
        return TieredRevocationRollupValidator(
            rules: [
                TieredRevocationRollupRequiredLabelRule(message: "tiered revocation rollup needs a value"),
                TieredRevocationRollupAcuityRangeRule(min: 16, max: 86400),
                TieredRevocationRollupAllergyLengthRule(maxLength: 120),
                TieredRevocationRollupLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
