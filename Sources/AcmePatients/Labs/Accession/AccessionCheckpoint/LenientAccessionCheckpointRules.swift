import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient accession checkpoint must pass. Check returns its problems, or none.
    protocol LenientAccessionCheckpointRule {
        func check(_ item: LenientAccessionCheckpoint) -> [String]
    }

    final class LenientAccessionCheckpointAllowedNameRule: LenientAccessionCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientAccessionCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class LenientAccessionCheckpointCodeLengthRule: LenientAccessionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientAccessionCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientAccessionCheckpointRatioRangeRule: LenientAccessionCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAccessionCheckpoint) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientAccessionCheckpointChannelLengthRule: LenientAccessionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientAccessionCheckpoint) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientAccessionCheckpointExpiresAtRangeRule: LenientAccessionCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAccessionCheckpoint) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientAccessionCheckpointRequiredNameRule: LenientAccessionCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAccessionCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient accession checkpoint.
    final class LenientAccessionCheckpointValidator {
        var rules: [any LenientAccessionCheckpointRule]

        init(rules: [any LenientAccessionCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientAccessionCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientAccessionCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientAccessionCheckpoint]) -> [String: [String]] {
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

    static func defaultLenientAccessionCheckpointValidator() -> LenientAccessionCheckpointValidator {
        return LenientAccessionCheckpointValidator(
            rules: [
                LenientAccessionCheckpointAllowedNameRule(allowed: []),
                LenientAccessionCheckpointCodeLengthRule(maxLength: 255),
                LenientAccessionCheckpointRatioRangeRule(min: 0.2, max: 1863.6),
                LenientAccessionCheckpointChannelLengthRule(maxLength: 64),
                LenientAccessionCheckpointExpiresAtRangeRule(min: 32, max: 64),
                LenientAccessionCheckpointRequiredNameRule(message: "lenient accession checkpoint needs a value"),
            ]
        )
    }
}
