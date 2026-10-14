import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending transfer draft must pass. Check returns its problems, or none.
    protocol PendingTransferDraftRule {
        func check(_ item: PendingTransferDraft) -> [String]
    }

    final class PendingTransferDraftRequiredPatientRefRule: PendingTransferDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingTransferDraft) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingTransferDraftWindowDaysRangeRule: PendingTransferDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingTransferDraft) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingTransferDraftPatientRefLengthRule: PendingTransferDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingTransferDraft) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending transfer draft.
    final class PendingTransferDraftValidator {
        var rules: [any PendingTransferDraftRule]

        init(rules: [any PendingTransferDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingTransferDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingTransferDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingTransferDraft]) -> [String: [String]] {
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

    static func defaultPendingTransferDraftValidator() -> PendingTransferDraftValidator {
        return PendingTransferDraftValidator(
            rules: [
                PendingTransferDraftRequiredPatientRefRule(message: "pending transfer draft needs a value"),
                PendingTransferDraftWindowDaysRangeRule(min: 16, max: 32),
                PendingTransferDraftPatientRefLengthRule(maxLength: 64),
            ]
        )
    }
}
