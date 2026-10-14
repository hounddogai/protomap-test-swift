import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral checkpoint must pass. Check returns its problems, or none.
    protocol ReferralCheckpointRule {
        func check(_ item: ReferralCheckpoint) -> [String]
    }

    final class ReferralCheckpointRequiredCodeRule: ReferralCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralCheckpointAllowedCodeRule: ReferralCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ReferralCheckpointNameLengthRule: ReferralCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralCheckpointRatioRangeRule: ReferralCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralCheckpoint) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralCheckpointPinnedGuardRule: ReferralCheckpointRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ReferralCheckpoint) -> [String] {
            if item.pinned && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a referral checkpoint.
    final class ReferralCheckpointValidator {
        var rules: [any ReferralCheckpointRule]

        init(rules: [any ReferralCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralCheckpoint) -> [String] {
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

        func requireValid(_ item: ReferralCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralCheckpoint]) -> [String: [String]] {
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

    static func defaultReferralCheckpointValidator() -> ReferralCheckpointValidator {
        return ReferralCheckpointValidator(
            rules: [
                ReferralCheckpointRequiredCodeRule(message: "referral checkpoint needs this field"),
                ReferralCheckpointAllowedCodeRule(allowed: ["pending", "adaptive"]),
                ReferralCheckpointNameLengthRule(maxLength: 255),
                ReferralCheckpointRatioRangeRule(min: 7.8, max: 1018.6),
                ReferralCheckpointPinnedGuardRule(limit: 8.0),
            ]
        )
    }
}
