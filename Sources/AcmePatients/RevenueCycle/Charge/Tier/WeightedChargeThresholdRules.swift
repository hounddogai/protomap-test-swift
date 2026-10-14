import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted charge threshold must pass. Check returns its problems, or none.
    protocol WeightedChargeThresholdRule {
        func check(_ item: WeightedChargeThreshold) -> [String]
    }

    final class WeightedChargeThresholdRequiredNotesRule: WeightedChargeThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedChargeThreshold) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedChargeThresholdNameLengthRule: WeightedChargeThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedChargeThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedChargeThresholdRequiredCodeRule: WeightedChargeThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedChargeThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedChargeThresholdAllowedCodeRule: WeightedChargeThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedChargeThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class WeightedChargeThresholdRequiredNameRule: WeightedChargeThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedChargeThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedChargeThresholdRefillsRangeRule: WeightedChargeThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedChargeThreshold) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted charge threshold.
    final class WeightedChargeThresholdValidator {
        var rules: [any WeightedChargeThresholdRule]

        init(rules: [any WeightedChargeThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedChargeThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedChargeThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedChargeThreshold]) -> [String: [String]] {
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

    static func defaultWeightedChargeThresholdValidator() -> WeightedChargeThresholdValidator {
        return WeightedChargeThresholdValidator(
            rules: [
                WeightedChargeThresholdRequiredNotesRule(message: "weighted charge threshold needs this field"),
                WeightedChargeThresholdNameLengthRule(maxLength: 1000),
                WeightedChargeThresholdRequiredCodeRule(message: "weighted charge threshold needs this field"),
                WeightedChargeThresholdAllowedCodeRule(allowed: ["legacy", "weighted", "adaptive"]),
                WeightedChargeThresholdRequiredNameRule(message: "weighted charge threshold needs this field"),
                WeightedChargeThresholdRefillsRangeRule(min: 64, max: 255),
            ]
        )
    }
}
