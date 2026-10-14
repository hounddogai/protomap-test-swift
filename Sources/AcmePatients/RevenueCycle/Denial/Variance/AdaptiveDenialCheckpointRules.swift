import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive denial checkpoint must pass. Check returns its problems, or none.
    protocol AdaptiveDenialCheckpointRule {
        func check(_ item: AdaptiveDenialCheckpoint) -> [String]
    }

    final class AdaptiveDenialCheckpointCodeLengthRule: AdaptiveDenialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDenialCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDenialCheckpointUnitLengthRule: AdaptiveDenialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDenialCheckpoint) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDenialCheckpointRequiredUnitRule: AdaptiveDenialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDenialCheckpoint) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDenialCheckpointBatchSizeRangeRule: AdaptiveDenialCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDenialCheckpoint) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveDenialCheckpointAllowedLabelRule: AdaptiveDenialCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveDenialCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive denial checkpoint.
    final class AdaptiveDenialCheckpointValidator {
        var rules: [any AdaptiveDenialCheckpointRule]

        init(rules: [any AdaptiveDenialCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDenialCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveDenialCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDenialCheckpoint]) -> [String: [String]] {
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

    static func defaultAdaptiveDenialCheckpointValidator() -> AdaptiveDenialCheckpointValidator {
        return AdaptiveDenialCheckpointValidator(
            rules: [
                AdaptiveDenialCheckpointCodeLengthRule(maxLength: 255),
                AdaptiveDenialCheckpointUnitLengthRule(maxLength: 255),
                AdaptiveDenialCheckpointRequiredUnitRule(message: "adaptive denial checkpoint needs an entry"),
                AdaptiveDenialCheckpointBatchSizeRangeRule(min: 64, max: 1000),
                AdaptiveDenialCheckpointAllowedLabelRule(allowed: ["batched"]),
            ]
        )
    }
}
