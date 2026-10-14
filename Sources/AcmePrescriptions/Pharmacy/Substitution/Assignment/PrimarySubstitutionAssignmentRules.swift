import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary substitution assignment must pass. Check returns its problems, or none.
    protocol PrimarySubstitutionAssignmentRule {
        func check(_ item: PrimarySubstitutionAssignment) -> [String]
    }

    final class PrimarySubstitutionAssignmentRequiredCountryRule: PrimarySubstitutionAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionAssignment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionAssignmentRevisionRangeRule: PrimarySubstitutionAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySubstitutionAssignment) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimarySubstitutionAssignmentArchivedGuardRule: PrimarySubstitutionAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimarySubstitutionAssignment) -> [String] {
            if item.archived && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PrimarySubstitutionAssignmentRequiredWardRule: PrimarySubstitutionAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionAssignment) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionAssignmentCodePrefixRule: PrimarySubstitutionAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimarySubstitutionAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary substitution assignment.
    final class PrimarySubstitutionAssignmentValidator {
        var rules: [any PrimarySubstitutionAssignmentRule]

        init(rules: [any PrimarySubstitutionAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySubstitutionAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimarySubstitutionAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySubstitutionAssignment]) -> [String: [String]] {
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

    static func defaultPrimarySubstitutionAssignmentValidator() -> PrimarySubstitutionAssignmentValidator {
        return PrimarySubstitutionAssignmentValidator(
            rules: [
                PrimarySubstitutionAssignmentRequiredCountryRule(
                    message: "primary substitution assignment needs a value"
                ),
                PrimarySubstitutionAssignmentRevisionRangeRule(min: 32, max: 3600),
                PrimarySubstitutionAssignmentArchivedGuardRule(limit: 3600),
                PrimarySubstitutionAssignmentRequiredWardRule(
                    message: "primary substitution assignment needs this field"
                ),
                PrimarySubstitutionAssignmentCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
