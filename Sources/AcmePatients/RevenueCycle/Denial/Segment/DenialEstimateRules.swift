import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial estimate must pass. Check returns its problems, or none.
    protocol DenialEstimateRule {
        func check(_ item: DenialEstimate) -> [String]
    }

    final class DenialEstimateNotesLengthRule: DenialEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialEstimate) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialEstimateCodeLengthRule: DenialEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialEstimateLabelLengthRule: DenialEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialEstimateRequiredNotesRule: DenialEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialEstimate) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialEstimateRequiredCodeRule: DenialEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial estimate.
    final class DenialEstimateValidator {
        var rules: [any DenialEstimateRule]

        init(rules: [any DenialEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialEstimate) -> [String] {
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

        func requireValid(_ item: DenialEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialEstimate]) -> [String: [String]] {
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

    static func defaultDenialEstimateValidator() -> DenialEstimateValidator {
        return DenialEstimateValidator(
            rules: [
                DenialEstimateNotesLengthRule(maxLength: 3600),
                DenialEstimateCodeLengthRule(maxLength: 86400),
                DenialEstimateLabelLengthRule(maxLength: 32),
                DenialEstimateRequiredNotesRule(message: "denial estimate needs a value"),
                DenialEstimateRequiredCodeRule(message: "denial estimate needs this field"),
            ]
        )
    }
}
