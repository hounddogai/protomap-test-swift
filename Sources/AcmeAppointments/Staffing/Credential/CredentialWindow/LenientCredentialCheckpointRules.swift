import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient credential checkpoint must pass. Check returns its problems, or none.
    protocol LenientCredentialCheckpointRule {
        func check(_ item: LenientCredentialCheckpoint) -> [String]
    }

    final class LenientCredentialCheckpointRatioRangeRule: LenientCredentialCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCredentialCheckpoint) -> [String] {
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

    final class LenientCredentialCheckpointRequiredTitleRule: LenientCredentialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCredentialCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCredentialCheckpointCodeLengthRule: LenientCredentialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCredentialCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCredentialCheckpointRequiredOwnerIDRule: LenientCredentialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCredentialCheckpoint) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient credential checkpoint.
    final class LenientCredentialCheckpointValidator {
        var rules: [any LenientCredentialCheckpointRule]

        init(rules: [any LenientCredentialCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCredentialCheckpoint) -> [String] {
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

        func requireValid(_ item: LenientCredentialCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCredentialCheckpoint]) -> [String: [String]] {
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

    static func defaultLenientCredentialCheckpointValidator() -> LenientCredentialCheckpointValidator {
        return LenientCredentialCheckpointValidator(
            rules: [
                LenientCredentialCheckpointRatioRangeRule(min: 0.7, max: 1075.6),
                LenientCredentialCheckpointRequiredTitleRule(message: "lenient credential checkpoint needs a value"),
                LenientCredentialCheckpointCodeLengthRule(maxLength: 1000),
                LenientCredentialCheckpointRequiredOwnerIDRule(message: "lenient credential checkpoint needs a value"),
            ]
        )
    }
}
