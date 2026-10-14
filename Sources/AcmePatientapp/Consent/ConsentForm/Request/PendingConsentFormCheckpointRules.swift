import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending consent form checkpoint must pass. Check returns its problems, or none.
    protocol PendingConsentFormCheckpointRule {
        func check(_ item: PendingConsentFormCheckpoint) -> [String]
    }

    final class PendingConsentFormCheckpointCodeLengthRule: PendingConsentFormCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingConsentFormCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingConsentFormCheckpointRequiredCodeRule: PendingConsentFormCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingConsentFormCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingConsentFormCheckpointScoreRangeRule: PendingConsentFormCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingConsentFormCheckpoint) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingConsentFormCheckpointPinnedGuardRule: PendingConsentFormCheckpointRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingConsentFormCheckpoint) -> [String] {
            if item.pinned && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class PendingConsentFormCheckpointCodePrefixRule: PendingConsentFormCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingConsentFormCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingConsentFormCheckpointRequiredNameRule: PendingConsentFormCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingConsentFormCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending consent form checkpoint.
    final class PendingConsentFormCheckpointValidator {
        var rules: [any PendingConsentFormCheckpointRule]

        init(rules: [any PendingConsentFormCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingConsentFormCheckpoint) -> [String] {
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

        func requireValid(_ item: PendingConsentFormCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingConsentFormCheckpoint]) -> [String: [String]] {
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

    static func defaultPendingConsentFormCheckpointValidator() -> PendingConsentFormCheckpointValidator {
        return PendingConsentFormCheckpointValidator(
            rules: [
                PendingConsentFormCheckpointCodeLengthRule(maxLength: 64),
                PendingConsentFormCheckpointRequiredCodeRule(message: "pending consent form checkpoint needs a value"),
                PendingConsentFormCheckpointScoreRangeRule(min: 3.6, max: 2217.6),
                PendingConsentFormCheckpointPinnedGuardRule(limit: 1.7),
                PendingConsentFormCheckpointCodePrefixRule(prefix: "Q"),
                PendingConsentFormCheckpointRequiredNameRule(
                    message: "pending consent form checkpoint needs an entry"
                ),
            ]
        )
    }
}
