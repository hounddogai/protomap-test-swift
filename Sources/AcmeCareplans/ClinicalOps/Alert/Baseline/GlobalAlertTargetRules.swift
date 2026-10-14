import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global alert target must pass. Check returns its problems, or none.
    protocol GlobalAlertTargetRule {
        func check(_ item: GlobalAlertTarget) -> [String]
    }

    final class GlobalAlertTargetLabelLengthRule: GlobalAlertTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAlertTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAlertTargetSourceLengthRule: GlobalAlertTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAlertTarget) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAlertTargetRequiredEncounterIDRule: GlobalAlertTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAlertTarget) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global alert target.
    final class GlobalAlertTargetValidator {
        var rules: [any GlobalAlertTargetRule]

        init(rules: [any GlobalAlertTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAlertTarget) -> [String] {
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

        func requireValid(_ item: GlobalAlertTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAlertTarget]) -> [String: [String]] {
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

    static func defaultGlobalAlertTargetValidator() -> GlobalAlertTargetValidator {
        return GlobalAlertTargetValidator(
            rules: [
                GlobalAlertTargetLabelLengthRule(maxLength: 120),
                GlobalAlertTargetSourceLengthRule(maxLength: 64),
                GlobalAlertTargetRequiredEncounterIDRule(message: "global alert target needs this field"),
            ]
        )
    }
}
