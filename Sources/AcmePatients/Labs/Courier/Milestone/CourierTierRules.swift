import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier tier must pass. Check returns its problems, or none.
    protocol CourierTierRule {
        func check(_ item: CourierTier) -> [String]
    }

    final class CourierTierCodePrefixRule: CourierTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierTierAllowedAllergyRule: CourierTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is inconsistent"]
            }
            return []
        }
    }

    final class CourierTierVisibleGuardRule: CourierTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CourierTier) -> [String] {
            if item.visible && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CourierTierAllergyLengthRule: CourierTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierTier) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierTierBatchSizeRangeRule: CourierTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierTier) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a courier tier.
    final class CourierTierValidator {
        var rules: [any CourierTierRule]

        init(rules: [any CourierTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierTier) -> [String] {
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

        func requireValid(_ item: CourierTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierTier]) -> [String: [String]] {
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

    static func defaultCourierTierValidator() -> CourierTierValidator {
        return CourierTierValidator(
            rules: [
                CourierTierCodePrefixRule(prefix: "REF"),
                CourierTierAllowedAllergyRule(allowed: ["fallback", "global", "seasonal"]),
                CourierTierVisibleGuardRule(limit: 120),
                CourierTierAllergyLengthRule(maxLength: 64),
                CourierTierBatchSizeRangeRule(min: 16, max: 255),
            ]
        )
    }
}
