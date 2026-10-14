import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped accession checkpoint must pass. Check returns its problems, or none.
    protocol CappedAccessionCheckpointRule {
        func check(_ item: CappedAccessionCheckpoint) -> [String]
    }

    final class CappedAccessionCheckpointPatientRefLengthRule: CappedAccessionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAccessionCheckpoint) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAccessionCheckpointCodePrefixRule: CappedAccessionCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedAccessionCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedAccessionCheckpointAttemptsRangeRule: CappedAccessionCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedAccessionCheckpoint) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedAccessionCheckpointCodeLengthRule: CappedAccessionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAccessionCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped accession checkpoint.
    final class CappedAccessionCheckpointValidator {
        var rules: [any CappedAccessionCheckpointRule]

        init(rules: [any CappedAccessionCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedAccessionCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedAccessionCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedAccessionCheckpoint]) -> [String: [String]] {
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

    static func defaultCappedAccessionCheckpointValidator() -> CappedAccessionCheckpointValidator {
        return CappedAccessionCheckpointValidator(
            rules: [
                CappedAccessionCheckpointPatientRefLengthRule(maxLength: 32),
                CappedAccessionCheckpointCodePrefixRule(prefix: "ACM"),
                CappedAccessionCheckpointAttemptsRangeRule(min: 80, max: 86400),
                CappedAccessionCheckpointCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
