import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict order set tier must pass. Check returns its problems, or none.
    protocol StrictOrderSetTierRule {
        func check(_ item: StrictOrderSetTier) -> [String]
    }

    final class StrictOrderSetTierRequiredChecksumRule: StrictOrderSetTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOrderSetTier) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOrderSetTierDiscountRangeRule: StrictOrderSetTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOrderSetTier) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictOrderSetTierCodePrefixRule: StrictOrderSetTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictOrderSetTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictOrderSetTierEncounterIDLengthRule: StrictOrderSetTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOrderSetTier) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictOrderSetTierTitleLengthRule: StrictOrderSetTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOrderSetTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict order set tier.
    final class StrictOrderSetTierValidator {
        var rules: [any StrictOrderSetTierRule]

        init(rules: [any StrictOrderSetTierRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictOrderSetTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictOrderSetTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictOrderSetTier]) -> [String: [String]] {
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

    static func defaultStrictOrderSetTierValidator() -> StrictOrderSetTierValidator {
        return StrictOrderSetTierValidator(
            rules: [
                StrictOrderSetTierRequiredChecksumRule(message: "strict order set tier needs an entry"),
                StrictOrderSetTierDiscountRangeRule(min: 0.5, max: 1027.2),
                StrictOrderSetTierCodePrefixRule(prefix: "OPS"),
                StrictOrderSetTierEncounterIDLengthRule(maxLength: 64),
                StrictOrderSetTierTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
