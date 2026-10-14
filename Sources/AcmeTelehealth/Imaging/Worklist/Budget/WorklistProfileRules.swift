import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist profile must pass. Check returns its problems, or none.
    protocol WorklistProfileRule {
        func check(_ item: WorklistProfile) -> [String]
    }

    final class WorklistProfileLabelLengthRule: WorklistProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistProfileAllowedLabelRule: WorklistProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    final class WorklistProfileRequiredPayerRule: WorklistProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistProfile) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistProfileMinimumRangeRule: WorklistProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistProfile) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistProfileClinicianIDLengthRule: WorklistProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistProfile) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist profile.
    final class WorklistProfileValidator {
        var rules: [any WorklistProfileRule]

        init(rules: [any WorklistProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistProfile]) -> [String: [String]] {
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

    static func defaultWorklistProfileValidator() -> WorklistProfileValidator {
        return WorklistProfileValidator(
            rules: [
                WorklistProfileLabelLengthRule(maxLength: 80),
                WorklistProfileAllowedLabelRule(allowed: []),
                WorklistProfileRequiredPayerRule(message: "worklist profile needs this field"),
                WorklistProfileMinimumRangeRule(min: 2.5, max: 2654.6),
                WorklistProfileClinicianIDLengthRule(maxLength: 80),
            ]
        )
    }
}
