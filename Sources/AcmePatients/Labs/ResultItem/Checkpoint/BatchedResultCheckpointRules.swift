import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched result checkpoint must pass. Check returns its problems, or none.
    protocol BatchedResultCheckpointRule {
        func check(_ item: BatchedResultCheckpoint) -> [String]
    }

    final class BatchedResultCheckpointRequiredTitleRule: BatchedResultCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedResultCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedResultCheckpointRequiredPatientRefRule: BatchedResultCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedResultCheckpoint) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedResultCheckpointCountryLengthRule: BatchedResultCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedResultCheckpoint) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedResultCheckpointPatientRefLengthRule: BatchedResultCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedResultCheckpoint) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedResultCheckpointAllowedCountryRule: BatchedResultCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedResultCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is inconsistent"]
            }
            return []
        }
    }

    final class BatchedResultCheckpointCodePrefixRule: BatchedResultCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedResultCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched result checkpoint.
    final class BatchedResultCheckpointValidator {
        var rules: [any BatchedResultCheckpointRule]

        init(rules: [any BatchedResultCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedResultCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedResultCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedResultCheckpoint]) -> [String: [String]] {
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

    static func defaultBatchedResultCheckpointValidator() -> BatchedResultCheckpointValidator {
        return BatchedResultCheckpointValidator(
            rules: [
                BatchedResultCheckpointRequiredTitleRule(message: "batched result checkpoint needs this field"),
                BatchedResultCheckpointRequiredPatientRefRule(message: "batched result checkpoint needs this field"),
                BatchedResultCheckpointCountryLengthRule(maxLength: 86400),
                BatchedResultCheckpointPatientRefLengthRule(maxLength: 1000),
                BatchedResultCheckpointAllowedCountryRule(allowed: []),
                BatchedResultCheckpointCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
