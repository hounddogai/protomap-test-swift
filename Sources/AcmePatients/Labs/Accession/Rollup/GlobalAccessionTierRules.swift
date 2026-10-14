import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global accession tier must pass. Check returns its problems, or none.
    protocol GlobalAccessionTierRule {
        func check(_ item: GlobalAccessionTier) -> [String]
    }

    final class GlobalAccessionTierRequiredWardRule: GlobalAccessionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAccessionTier) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAccessionTierLocaleLengthRule: GlobalAccessionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAccessionTier) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAccessionTierWindowDaysRangeRule: GlobalAccessionTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAccessionTier) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global accession tier.
    final class GlobalAccessionTierValidator {
        var rules: [any GlobalAccessionTierRule]

        init(rules: [any GlobalAccessionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAccessionTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAccessionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAccessionTier]) -> [String: [String]] {
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

    static func defaultGlobalAccessionTierValidator() -> GlobalAccessionTierValidator {
        return GlobalAccessionTierValidator(
            rules: [
                GlobalAccessionTierRequiredWardRule(message: "global accession tier needs this field"),
                GlobalAccessionTierLocaleLengthRule(maxLength: 120),
                GlobalAccessionTierWindowDaysRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
