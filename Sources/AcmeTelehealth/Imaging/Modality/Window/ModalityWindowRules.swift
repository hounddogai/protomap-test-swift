import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality window must pass. Check returns its problems, or none.
    protocol ModalityWindowRule {
        func check(_ item: ModalityWindow) -> [String]
    }

    final class ModalityWindowRequiredCodeRule: ModalityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityWindowRequiredDescriptionRule: ModalityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityWindow) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityWindowClinicianIDLengthRule: ModalityWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityWindow) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityWindowAttemptsRangeRule: ModalityWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityWindow) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality window.
    final class ModalityWindowValidator {
        var rules: [any ModalityWindowRule]

        init(rules: [any ModalityWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityWindow]) -> [String: [String]] {
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

    static func defaultModalityWindowValidator() -> ModalityWindowValidator {
        return ModalityWindowValidator(
            rules: [
                ModalityWindowRequiredCodeRule(message: "modality window needs this field"),
                ModalityWindowRequiredDescriptionRule(message: "modality window needs this field"),
                ModalityWindowClinicianIDLengthRule(maxLength: 255),
                ModalityWindowAttemptsRangeRule(min: 80, max: 80),
            ]
        )
    }
}
