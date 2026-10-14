import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive risk score checkpoint must pass. Check returns its problems, or none.
    protocol AdaptiveRiskScoreCheckpointRule {
        func check(_ item: AdaptiveRiskScoreCheckpoint) -> [String]
    }

    final class AdaptiveRiskScoreCheckpointCeilingRangeRule: AdaptiveRiskScoreCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRiskScoreCheckpoint) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveRiskScoreCheckpointCodePrefixRule: AdaptiveRiskScoreCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveRiskScoreCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreCheckpointRequiredNameRule: AdaptiveRiskScoreCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRiskScoreCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreCheckpointBatchSizeRangeRule: AdaptiveRiskScoreCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRiskScoreCheckpoint) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveRiskScoreCheckpointNameLengthRule: AdaptiveRiskScoreCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive risk score checkpoint.
    final class AdaptiveRiskScoreCheckpointValidator {
        var rules: [any AdaptiveRiskScoreCheckpointRule]

        init(rules: [any AdaptiveRiskScoreCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRiskScoreCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveRiskScoreCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRiskScoreCheckpoint]) -> [String: [String]] {
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

    static func defaultAdaptiveRiskScoreCheckpointValidator() -> AdaptiveRiskScoreCheckpointValidator {
        return AdaptiveRiskScoreCheckpointValidator(
            rules: [
                AdaptiveRiskScoreCheckpointCeilingRangeRule(min: 6.8, max: 437.4),
                AdaptiveRiskScoreCheckpointCodePrefixRule(prefix: "OPS"),
                AdaptiveRiskScoreCheckpointRequiredNameRule(message: "adaptive risk score checkpoint needs an entry"),
                AdaptiveRiskScoreCheckpointBatchSizeRangeRule(min: 80, max: 3600),
                AdaptiveRiskScoreCheckpointNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
