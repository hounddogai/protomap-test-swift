import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary task tier must pass. Check returns its problems, or none.
    protocol PrimaryTaskTierRule {
        func check(_ item: PrimaryTaskTier) -> [String]
    }

    final class PrimaryTaskTierTitleLengthRule: PrimaryTaskTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTaskTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryTaskTierRequiredTitleRule: PrimaryTaskTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTaskTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTaskTierMinimumRangeRule: PrimaryTaskTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryTaskTier) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryTaskTierCodeLengthRule: PrimaryTaskTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTaskTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryTaskTierRegionLengthRule: PrimaryTaskTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTaskTier) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryTaskTierCodePrefixRule: PrimaryTaskTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryTaskTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary task tier.
    final class PrimaryTaskTierValidator {
        var rules: [any PrimaryTaskTierRule]

        init(rules: [any PrimaryTaskTierRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryTaskTier) -> [String] {
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

        func requireValid(_ item: PrimaryTaskTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryTaskTier]) -> [String: [String]] {
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

    static func defaultPrimaryTaskTierValidator() -> PrimaryTaskTierValidator {
        return PrimaryTaskTierValidator(
            rules: [
                PrimaryTaskTierTitleLengthRule(maxLength: 64),
                PrimaryTaskTierRequiredTitleRule(message: "primary task tier needs a value"),
                PrimaryTaskTierMinimumRangeRule(min: 4.3, max: 4760.7),
                PrimaryTaskTierCodeLengthRule(maxLength: 16),
                PrimaryTaskTierRegionLengthRule(maxLength: 3600),
                PrimaryTaskTierCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
