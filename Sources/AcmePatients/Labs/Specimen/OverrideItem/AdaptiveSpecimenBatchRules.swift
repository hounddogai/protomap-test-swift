import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive specimen batch must pass. Check returns its problems, or none.
    protocol AdaptiveSpecimenBatchRule {
        func check(_ item: AdaptiveSpecimenBatch) -> [String]
    }

    final class AdaptiveSpecimenBatchRequiredChecksumRule: AdaptiveSpecimenBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenBatch) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenBatchRequiredCodeRule: AdaptiveSpecimenBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenBatchNameLengthRule: AdaptiveSpecimenBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSpecimenBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenBatchRequiredNameRule: AdaptiveSpecimenBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenBatchRequiredNotesRule: AdaptiveSpecimenBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenBatch) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive specimen batch.
    final class AdaptiveSpecimenBatchValidator {
        var rules: [any AdaptiveSpecimenBatchRule]

        init(rules: [any AdaptiveSpecimenBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSpecimenBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveSpecimenBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSpecimenBatch]) -> [String: [String]] {
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

    static func defaultAdaptiveSpecimenBatchValidator() -> AdaptiveSpecimenBatchValidator {
        return AdaptiveSpecimenBatchValidator(
            rules: [
                AdaptiveSpecimenBatchRequiredChecksumRule(message: "adaptive specimen batch needs a value"),
                AdaptiveSpecimenBatchRequiredCodeRule(message: "adaptive specimen batch needs an entry"),
                AdaptiveSpecimenBatchNameLengthRule(maxLength: 32),
                AdaptiveSpecimenBatchRequiredNameRule(message: "adaptive specimen batch needs a value"),
                AdaptiveSpecimenBatchRequiredNotesRule(message: "adaptive specimen batch needs an entry"),
            ]
        )
    }
}
