import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy network score must pass. Check returns its problems, or none.
    protocol LegacyNetworkScoreRule {
        func check(_ item: LegacyNetworkScore) -> [String]
    }

    final class LegacyNetworkScoreRequiredOwnerIDRule: LegacyNetworkScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyNetworkScore) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyNetworkScoreCodePrefixRule: LegacyNetworkScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyNetworkScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyNetworkScoreCreatedAtRangeRule: LegacyNetworkScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyNetworkScore) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyNetworkScoreRevisionRangeRule: LegacyNetworkScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyNetworkScore) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyNetworkScoreRequiredCodeRule: LegacyNetworkScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyNetworkScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyNetworkScoreWeightRangeRule: LegacyNetworkScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyNetworkScore) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy network score.
    final class LegacyNetworkScoreValidator {
        var rules: [any LegacyNetworkScoreRule]

        init(rules: [any LegacyNetworkScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyNetworkScore) -> [String] {
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

        func requireValid(_ item: LegacyNetworkScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyNetworkScore]) -> [String: [String]] {
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

    static func defaultLegacyNetworkScoreValidator() -> LegacyNetworkScoreValidator {
        return LegacyNetworkScoreValidator(
            rules: [
                LegacyNetworkScoreRequiredOwnerIDRule(message: "legacy network score needs this field"),
                LegacyNetworkScoreCodePrefixRule(prefix: "X"),
                LegacyNetworkScoreCreatedAtRangeRule(min: 255, max: 3600),
                LegacyNetworkScoreRevisionRangeRule(min: 80, max: 120),
                LegacyNetworkScoreRequiredCodeRule(message: "legacy network score needs this field"),
                LegacyNetworkScoreWeightRangeRule(min: 1.8, max: 4916.2),
            ]
        )
    }
}
