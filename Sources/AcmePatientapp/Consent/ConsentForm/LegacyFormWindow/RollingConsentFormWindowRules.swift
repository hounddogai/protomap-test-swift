import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling consent form window must pass. Check returns its problems, or none.
    protocol RollingConsentFormWindowRule {
        func check(_ item: RollingConsentFormWindow) -> [String]
    }

    final class RollingConsentFormWindowRequiredSpecialtyRule: RollingConsentFormWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormWindow) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormWindowPriorityRangeRule: RollingConsentFormWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingConsentFormWindow) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingConsentFormWindowClinicianIDLengthRule: RollingConsentFormWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingConsentFormWindow) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling consent form window.
    final class RollingConsentFormWindowValidator {
        var rules: [any RollingConsentFormWindowRule]

        init(rules: [any RollingConsentFormWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingConsentFormWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingConsentFormWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingConsentFormWindow]) -> [String: [String]] {
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

    static func defaultRollingConsentFormWindowValidator() -> RollingConsentFormWindowValidator {
        return RollingConsentFormWindowValidator(
            rules: [
                RollingConsentFormWindowRequiredSpecialtyRule(message: "rolling consent form window needs a value"),
                RollingConsentFormWindowPriorityRangeRule(min: 16, max: 3600),
                RollingConsentFormWindowClinicianIDLengthRule(maxLength: 255),
            ]
        )
    }
}
