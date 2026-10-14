import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure exception must pass. Check returns its problems, or none.
    protocol DisclosureExceptionRule {
        func check(_ item: DisclosureException) -> [String]
    }

    final class DisclosureExceptionContactEmailLengthRule: DisclosureExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureException) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureExceptionRequiredFacilityRule: DisclosureExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureException) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureExceptionRequiredNameRule: DisclosureExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure exception.
    final class DisclosureExceptionValidator {
        var rules: [any DisclosureExceptionRule]

        init(rules: [any DisclosureExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureException]) -> [String: [String]] {
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

    static func defaultDisclosureExceptionValidator() -> DisclosureExceptionValidator {
        return DisclosureExceptionValidator(
            rules: [
                DisclosureExceptionContactEmailLengthRule(maxLength: 1000),
                DisclosureExceptionRequiredFacilityRule(message: "disclosure exception needs this field"),
                DisclosureExceptionRequiredNameRule(message: "disclosure exception needs this field"),
            ]
        )
    }
}
