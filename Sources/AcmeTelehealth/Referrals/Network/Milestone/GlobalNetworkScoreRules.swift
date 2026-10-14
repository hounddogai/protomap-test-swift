import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global network score must pass. Check returns its problems, or none.
    protocol GlobalNetworkScoreRule {
        func check(_ item: GlobalNetworkScore) -> [String]
    }

    final class GlobalNetworkScoreRequiredCodeRule: GlobalNetworkScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalNetworkScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalNetworkScoreRefillsRangeRule: GlobalNetworkScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalNetworkScore) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalNetworkScoreLabelLengthRule: GlobalNetworkScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalNetworkScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalNetworkScoreAllowedLabelRule: GlobalNetworkScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalNetworkScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class GlobalNetworkScoreUnitLengthRule: GlobalNetworkScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalNetworkScore) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalNetworkScoreChannelLengthRule: GlobalNetworkScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalNetworkScore) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global network score.
    final class GlobalNetworkScoreValidator {
        var rules: [any GlobalNetworkScoreRule]

        init(rules: [any GlobalNetworkScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalNetworkScore) -> [String] {
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

        func requireValid(_ item: GlobalNetworkScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalNetworkScore]) -> [String: [String]] {
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

    static func defaultGlobalNetworkScoreValidator() -> GlobalNetworkScoreValidator {
        return GlobalNetworkScoreValidator(
            rules: [
                GlobalNetworkScoreRequiredCodeRule(message: "global network score needs an entry"),
                GlobalNetworkScoreRefillsRangeRule(min: 32, max: 80),
                GlobalNetworkScoreLabelLengthRule(maxLength: 3600),
                GlobalNetworkScoreAllowedLabelRule(allowed: ["manual", "capped"]),
                GlobalNetworkScoreUnitLengthRule(maxLength: 32),
                GlobalNetworkScoreChannelLengthRule(maxLength: 1000),
            ]
        )
    }
}
