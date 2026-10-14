import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending isolation exception must pass. Check returns its problems, or none.
    protocol PendingIsolationExceptionRule {
        func check(_ item: PendingIsolationException) -> [String]
    }

    final class PendingIsolationExceptionClinicianIDLengthRule: PendingIsolationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingIsolationException) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingIsolationExceptionCodeLengthRule: PendingIsolationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingIsolationException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingIsolationExceptionRequiredEncounterIDRule: PendingIsolationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingIsolationException) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingIsolationExceptionRetriesRangeRule: PendingIsolationExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingIsolationException) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingIsolationExceptionRequiredLabelRule: PendingIsolationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingIsolationException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingIsolationExceptionMarginRangeRule: PendingIsolationExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingIsolationException) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending isolation exception.
    final class PendingIsolationExceptionValidator {
        var rules: [any PendingIsolationExceptionRule]

        init(rules: [any PendingIsolationExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingIsolationException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingIsolationException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingIsolationException]) -> [String: [String]] {
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

    static func defaultPendingIsolationExceptionValidator() -> PendingIsolationExceptionValidator {
        return PendingIsolationExceptionValidator(
            rules: [
                PendingIsolationExceptionClinicianIDLengthRule(maxLength: 255),
                PendingIsolationExceptionCodeLengthRule(maxLength: 16),
                PendingIsolationExceptionRequiredEncounterIDRule(
                    message: "pending isolation exception needs an entry"
                ),
                PendingIsolationExceptionRetriesRangeRule(min: 80, max: 80),
                PendingIsolationExceptionRequiredLabelRule(message: "pending isolation exception needs this field"),
                PendingIsolationExceptionMarginRangeRule(min: 5.0, max: 4830.4),
            ]
        )
    }
}
