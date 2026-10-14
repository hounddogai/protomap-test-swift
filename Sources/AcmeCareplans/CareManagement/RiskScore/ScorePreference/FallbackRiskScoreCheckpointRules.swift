import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback risk score checkpoint must pass. Check returns its problems, or none.
    protocol FallbackRiskScoreCheckpointRule {
        func check(_ item: FallbackRiskScoreCheckpoint) -> [String]
    }

    final class FallbackRiskScoreCheckpointRequiredTitleRule: FallbackRiskScoreCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRiskScoreCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRiskScoreCheckpointCodePrefixRule: FallbackRiskScoreCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackRiskScoreCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackRiskScoreCheckpointChannelLengthRule: FallbackRiskScoreCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRiskScoreCheckpoint) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRiskScoreCheckpointRequiredCodeRule: FallbackRiskScoreCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRiskScoreCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRiskScoreCheckpointCodeLengthRule: FallbackRiskScoreCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRiskScoreCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRiskScoreCheckpointRequiredChannelRule: FallbackRiskScoreCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRiskScoreCheckpoint) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback risk score checkpoint.
    final class FallbackRiskScoreCheckpointValidator {
        var rules: [any FallbackRiskScoreCheckpointRule]

        init(rules: [any FallbackRiskScoreCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRiskScoreCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRiskScoreCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRiskScoreCheckpoint]) -> [String: [String]] {
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

    static func defaultFallbackRiskScoreCheckpointValidator() -> FallbackRiskScoreCheckpointValidator {
        return FallbackRiskScoreCheckpointValidator(
            rules: [
                FallbackRiskScoreCheckpointRequiredTitleRule(
                    message: "fallback risk score checkpoint needs this field"
                ),
                FallbackRiskScoreCheckpointCodePrefixRule(prefix: "REF"),
                FallbackRiskScoreCheckpointChannelLengthRule(maxLength: 86400),
                FallbackRiskScoreCheckpointRequiredCodeRule(message: "fallback risk score checkpoint needs a value"),
                FallbackRiskScoreCheckpointCodeLengthRule(maxLength: 86400),
                FallbackRiskScoreCheckpointRequiredChannelRule(
                    message: "fallback risk score checkpoint needs this field"
                ),
            ]
        )
    }
}
