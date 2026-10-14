import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched handoff window must pass. Check returns its problems, or none.
    protocol BatchedHandoffWindowRule {
        func check(_ item: BatchedHandoffWindow) -> [String]
    }

    final class BatchedHandoffWindowCodePrefixRule: BatchedHandoffWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedHandoffWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedHandoffWindowRequiredPatientRefRule: BatchedHandoffWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedHandoffWindow) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedHandoffWindowRequiredTitleRule: BatchedHandoffWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedHandoffWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedHandoffWindowRequiredClinicianIDRule: BatchedHandoffWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedHandoffWindow) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedHandoffWindowPatientRefLengthRule: BatchedHandoffWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedHandoffWindow) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched handoff window.
    final class BatchedHandoffWindowValidator {
        var rules: [any BatchedHandoffWindowRule]

        init(rules: [any BatchedHandoffWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedHandoffWindow) -> [String] {
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

        func requireValid(_ item: BatchedHandoffWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedHandoffWindow]) -> [String: [String]] {
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

    static func defaultBatchedHandoffWindowValidator() -> BatchedHandoffWindowValidator {
        return BatchedHandoffWindowValidator(
            rules: [
                BatchedHandoffWindowCodePrefixRule(prefix: "Q"),
                BatchedHandoffWindowRequiredPatientRefRule(message: "batched handoff window needs an entry"),
                BatchedHandoffWindowRequiredTitleRule(message: "batched handoff window needs this field"),
                BatchedHandoffWindowRequiredClinicianIDRule(message: "batched handoff window needs an entry"),
                BatchedHandoffWindowPatientRefLengthRule(maxLength: 32),
            ]
        )
    }
}
