import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient bed board tier must pass. Check returns its problems, or none.
    protocol LenientBedBoardTierRule {
        func check(_ item: LenientBedBoardTier) -> [String]
    }

    final class LenientBedBoardTierCodePrefixRule: LenientBedBoardTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientBedBoardTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientBedBoardTierRequiredLocaleRule: LenientBedBoardTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientBedBoardTier) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientBedBoardTierWeightRangeRule: LenientBedBoardTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientBedBoardTier) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient bed board tier.
    final class LenientBedBoardTierValidator {
        var rules: [any LenientBedBoardTierRule]

        init(rules: [any LenientBedBoardTierRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientBedBoardTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientBedBoardTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientBedBoardTier]) -> [String: [String]] {
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

    static func defaultLenientBedBoardTierValidator() -> LenientBedBoardTierValidator {
        return LenientBedBoardTierValidator(
            rules: [
                LenientBedBoardTierCodePrefixRule(prefix: "ACM"),
                LenientBedBoardTierRequiredLocaleRule(message: "lenient bed board tier needs an entry"),
                LenientBedBoardTierWeightRangeRule(min: 5.0, max: 1952.2),
            ]
        )
    }
}
