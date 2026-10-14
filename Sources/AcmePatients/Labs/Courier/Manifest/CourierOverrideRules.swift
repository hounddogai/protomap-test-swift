import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier override must pass. Check returns its problems, or none.
    protocol CourierOverrideRule {
        func check(_ item: CourierOverride) -> [String]
    }

    final class CourierOverrideRequiredNameRule: CourierOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierOverrideRequiredCodeRule: CourierOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierOverrideRequiredClinicianIDRule: CourierOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierOverride) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier override.
    final class CourierOverrideValidator {
        var rules: [any CourierOverrideRule]

        init(rules: [any CourierOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierOverride) -> [String] {
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

        func requireValid(_ item: CourierOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierOverride]) -> [String: [String]] {
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

    static func defaultCourierOverrideValidator() -> CourierOverrideValidator {
        return CourierOverrideValidator(
            rules: [
                CourierOverrideRequiredNameRule(message: "courier override needs an entry"),
                CourierOverrideRequiredCodeRule(message: "courier override needs a value"),
                CourierOverrideRequiredClinicianIDRule(message: "courier override needs an entry"),
            ]
        )
    }
}
