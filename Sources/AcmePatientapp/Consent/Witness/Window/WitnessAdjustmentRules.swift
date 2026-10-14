import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness adjustment must pass. Check returns its problems, or none.
    protocol WitnessAdjustmentRule {
        func check(_ item: WitnessAdjustment) -> [String]
    }

    final class WitnessAdjustmentEndsAtRangeRule: WitnessAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessAdjustment) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessAdjustmentChannelLengthRule: WitnessAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessAdjustment) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessAdjustmentCodePrefixRule: WitnessAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessAdjustmentAllowedCodeRule: WitnessAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class WitnessAdjustmentActiveGuardRule: WitnessAdjustmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WitnessAdjustment) -> [String] {
            if item.active && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a witness adjustment.
    final class WitnessAdjustmentValidator {
        var rules: [any WitnessAdjustmentRule]

        init(rules: [any WitnessAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessAdjustment]) -> [String: [String]] {
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

    static func defaultWitnessAdjustmentValidator() -> WitnessAdjustmentValidator {
        return WitnessAdjustmentValidator(
            rules: [
                WitnessAdjustmentEndsAtRangeRule(min: 80, max: 86400),
                WitnessAdjustmentChannelLengthRule(maxLength: 86400),
                WitnessAdjustmentCodePrefixRule(prefix: "ACM"),
                WitnessAdjustmentAllowedCodeRule(allowed: ["primary"]),
                WitnessAdjustmentActiveGuardRule(limit: 1000),
            ]
        )
    }
}
