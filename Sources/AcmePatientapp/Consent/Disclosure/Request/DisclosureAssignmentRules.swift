import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure assignment must pass. Check returns its problems, or none.
    protocol DisclosureAssignmentRule {
        func check(_ item: DisclosureAssignment) -> [String]
    }

    final class DisclosureAssignmentCodePrefixRule: DisclosureAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureAssignmentLocaleLengthRule: DisclosureAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureAssignment) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureAssignmentRequiredRegionRule: DisclosureAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureAssignment) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure assignment.
    final class DisclosureAssignmentValidator {
        var rules: [any DisclosureAssignmentRule]

        init(rules: [any DisclosureAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureAssignment]) -> [String: [String]] {
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

    static func defaultDisclosureAssignmentValidator() -> DisclosureAssignmentValidator {
        return DisclosureAssignmentValidator(
            rules: [
                DisclosureAssignmentCodePrefixRule(prefix: "Q"),
                DisclosureAssignmentLocaleLengthRule(maxLength: 64),
                DisclosureAssignmentRequiredRegionRule(message: "disclosure assignment needs a value"),
            ]
        )
    }
}
