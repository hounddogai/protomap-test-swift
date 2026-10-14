import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score checkpoint must pass. Check returns its problems, or none.
    protocol RiskScoreCheckpointRule {
        func check(_ item: RiskScoreCheckpoint) -> [String]
    }

    final class RiskScoreCheckpointCodePrefixRule: RiskScoreCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreCheckpointDescriptionLengthRule: RiskScoreCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreCheckpoint) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreCheckpointCodeLengthRule: RiskScoreCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreCheckpointRequiredCodeRule: RiskScoreCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a risk score checkpoint.
    final class RiskScoreCheckpointValidator {
        var rules: [any RiskScoreCheckpointRule]

        init(rules: [any RiskScoreCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreCheckpoint) -> [String] {
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

        func requireValid(_ item: RiskScoreCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreCheckpoint]) -> [String: [String]] {
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

    static func defaultRiskScoreCheckpointValidator() -> RiskScoreCheckpointValidator {
        return RiskScoreCheckpointValidator(
            rules: [
                RiskScoreCheckpointCodePrefixRule(prefix: "X"),
                RiskScoreCheckpointDescriptionLengthRule(maxLength: 120),
                RiskScoreCheckpointCodeLengthRule(maxLength: 80),
                RiskScoreCheckpointRequiredCodeRule(message: "risk score checkpoint needs an entry"),
            ]
        )
    }
}
