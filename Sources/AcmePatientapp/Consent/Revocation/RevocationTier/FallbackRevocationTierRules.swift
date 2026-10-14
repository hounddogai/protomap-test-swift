import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback revocation tier must pass. Check returns its problems, or none.
    protocol FallbackRevocationTierRule {
        func check(_ item: FallbackRevocationTier) -> [String]
    }

    final class FallbackRevocationTierRequiredRegionRule: FallbackRevocationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRevocationTier) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRevocationTierCreatedAtRangeRule: FallbackRevocationTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRevocationTier) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackRevocationTierUpdatedAtRangeRule: FallbackRevocationTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRevocationTier) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackRevocationTierRequiredLocaleRule: FallbackRevocationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRevocationTier) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRevocationTierLocaleLengthRule: FallbackRevocationTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRevocationTier) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRevocationTierRequiredLabelRule: FallbackRevocationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRevocationTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback revocation tier.
    final class FallbackRevocationTierValidator {
        var rules: [any FallbackRevocationTierRule]

        init(rules: [any FallbackRevocationTierRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRevocationTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRevocationTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRevocationTier]) -> [String: [String]] {
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

    static func defaultFallbackRevocationTierValidator() -> FallbackRevocationTierValidator {
        return FallbackRevocationTierValidator(
            rules: [
                FallbackRevocationTierRequiredRegionRule(message: "fallback revocation tier needs a value"),
                FallbackRevocationTierCreatedAtRangeRule(min: 120, max: 3600),
                FallbackRevocationTierUpdatedAtRangeRule(min: 255, max: 86400),
                FallbackRevocationTierRequiredLocaleRule(message: "fallback revocation tier needs an entry"),
                FallbackRevocationTierLocaleLengthRule(maxLength: 64),
                FallbackRevocationTierRequiredLabelRule(message: "fallback revocation tier needs a value"),
            ]
        )
    }
}
