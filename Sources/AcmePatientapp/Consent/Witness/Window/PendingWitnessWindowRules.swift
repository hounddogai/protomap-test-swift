import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending witness window must pass. Check returns its problems, or none.
    protocol PendingWitnessWindowRule {
        func check(_ item: PendingWitnessWindow) -> [String]
    }

    final class PendingWitnessWindowRequiredLocaleRule: PendingWitnessWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingWitnessWindow) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingWitnessWindowRequiredCodeRule: PendingWitnessWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingWitnessWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingWitnessWindowFacilityLengthRule: PendingWitnessWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWitnessWindow) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending witness window.
    final class PendingWitnessWindowValidator {
        var rules: [any PendingWitnessWindowRule]

        init(rules: [any PendingWitnessWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingWitnessWindow) -> [String] {
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

        func requireValid(_ item: PendingWitnessWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingWitnessWindow]) -> [String: [String]] {
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

    static func defaultPendingWitnessWindowValidator() -> PendingWitnessWindowValidator {
        return PendingWitnessWindowValidator(
            rules: [
                PendingWitnessWindowRequiredLocaleRule(message: "pending witness window needs this field"),
                PendingWitnessWindowRequiredCodeRule(message: "pending witness window needs this field"),
                PendingWitnessWindowFacilityLengthRule(maxLength: 86400),
            ]
        )
    }
}
