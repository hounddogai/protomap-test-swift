import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual cleaning estimate must pass. Check returns its problems, or none.
    protocol ManualCleaningEstimateRule {
        func check(_ item: ManualCleaningEstimate) -> [String]
    }

    final class ManualCleaningEstimateAllowedNameRule: ManualCleaningEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualCleaningEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class ManualCleaningEstimateRequiredContactEmailRule: ManualCleaningEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCleaningEstimate) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCleaningEstimateNotesLengthRule: ManualCleaningEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCleaningEstimate) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCleaningEstimateCodeLengthRule: ManualCleaningEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCleaningEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual cleaning estimate.
    final class ManualCleaningEstimateValidator {
        var rules: [any ManualCleaningEstimateRule]

        init(rules: [any ManualCleaningEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCleaningEstimate) -> [String] {
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

        func requireValid(_ item: ManualCleaningEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCleaningEstimate]) -> [String: [String]] {
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

    static func defaultManualCleaningEstimateValidator() -> ManualCleaningEstimateValidator {
        return ManualCleaningEstimateValidator(
            rules: [
                ManualCleaningEstimateAllowedNameRule(allowed: ["adaptive", "global"]),
                ManualCleaningEstimateRequiredContactEmailRule(message: "manual cleaning estimate needs an entry"),
                ManualCleaningEstimateNotesLengthRule(maxLength: 64),
                ManualCleaningEstimateCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
