import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier profile must pass. Check returns its problems, or none.
    protocol CourierProfileRule {
        func check(_ item: CourierProfile) -> [String]
    }

    final class CourierProfileAllowedTitleRule: CourierProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class CourierProfileRequiredSourceRule: CourierProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierProfile) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierProfileAllergyLengthRule: CourierProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierProfile) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierProfileRequiredCodeRule: CourierProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier profile.
    final class CourierProfileValidator {
        var rules: [any CourierProfileRule]

        init(rules: [any CourierProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierProfile) -> [String] {
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

        func requireValid(_ item: CourierProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierProfile]) -> [String: [String]] {
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

    static func defaultCourierProfileValidator() -> CourierProfileValidator {
        return CourierProfileValidator(
            rules: [
                CourierProfileAllowedTitleRule(allowed: []),
                CourierProfileRequiredSourceRule(message: "courier profile needs an entry"),
                CourierProfileAllergyLengthRule(maxLength: 32),
                CourierProfileRequiredCodeRule(message: "courier profile needs a value"),
            ]
        )
    }
}
