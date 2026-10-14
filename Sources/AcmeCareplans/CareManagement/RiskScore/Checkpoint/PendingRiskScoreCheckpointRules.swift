import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending risk score checkpoint must pass. Check returns its problems, or none.
    protocol PendingRiskScoreCheckpointRule {
        func check(_ item: PendingRiskScoreCheckpoint) -> [String]
    }

    final class PendingRiskScoreCheckpointRevisionRangeRule: PendingRiskScoreCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRiskScoreCheckpoint) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingRiskScoreCheckpointRequiredCodeRule: PendingRiskScoreCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRiskScoreCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRiskScoreCheckpointCodeLengthRule: PendingRiskScoreCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRiskScoreCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRiskScoreCheckpointRequiredSegmentRule: PendingRiskScoreCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRiskScoreCheckpoint) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRiskScoreCheckpointAllowedCurrencyRule: PendingRiskScoreCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingRiskScoreCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a pending risk score checkpoint.
    final class PendingRiskScoreCheckpointValidator {
        var rules: [any PendingRiskScoreCheckpointRule]

        init(rules: [any PendingRiskScoreCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRiskScoreCheckpoint) -> [String] {
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

        func requireValid(_ item: PendingRiskScoreCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRiskScoreCheckpoint]) -> [String: [String]] {
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

    static func defaultPendingRiskScoreCheckpointValidator() -> PendingRiskScoreCheckpointValidator {
        return PendingRiskScoreCheckpointValidator(
            rules: [
                PendingRiskScoreCheckpointRevisionRangeRule(min: 80, max: 86400),
                PendingRiskScoreCheckpointRequiredCodeRule(message: "pending risk score checkpoint needs this field"),
                PendingRiskScoreCheckpointCodeLengthRule(maxLength: 1000),
                PendingRiskScoreCheckpointRequiredSegmentRule(message: "pending risk score checkpoint needs an entry"),
                PendingRiskScoreCheckpointAllowedCurrencyRule(allowed: ["adaptive"]),
            ]
        )
    }
}
