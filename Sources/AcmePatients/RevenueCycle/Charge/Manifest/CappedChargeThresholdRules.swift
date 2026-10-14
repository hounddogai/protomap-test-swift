import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped charge threshold must pass. Check returns its problems, or none.
    protocol CappedChargeThresholdRule {
        func check(_ item: CappedChargeThreshold) -> [String]
    }

    final class CappedChargeThresholdTitleLengthRule: CappedChargeThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedChargeThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedChargeThresholdCountryLengthRule: CappedChargeThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedChargeThreshold) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedChargeThresholdAllowedCategoryRule: CappedChargeThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedChargeThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is expired"]
            }
            return []
        }
    }

    final class CappedChargeThresholdRequiredCodeRule: CappedChargeThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedChargeThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedChargeThresholdUpdatedAtRangeRule: CappedChargeThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedChargeThreshold) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedChargeThresholdCodePrefixRule: CappedChargeThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedChargeThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped charge threshold.
    final class CappedChargeThresholdValidator {
        var rules: [any CappedChargeThresholdRule]

        init(rules: [any CappedChargeThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedChargeThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedChargeThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedChargeThreshold]) -> [String: [String]] {
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

    static func defaultCappedChargeThresholdValidator() -> CappedChargeThresholdValidator {
        return CappedChargeThresholdValidator(
            rules: [
                CappedChargeThresholdTitleLengthRule(maxLength: 16),
                CappedChargeThresholdCountryLengthRule(maxLength: 120),
                CappedChargeThresholdAllowedCategoryRule(allowed: ["manual"]),
                CappedChargeThresholdRequiredCodeRule(message: "capped charge threshold needs an entry"),
                CappedChargeThresholdUpdatedAtRangeRule(min: 64, max: 1000),
                CappedChargeThresholdCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
