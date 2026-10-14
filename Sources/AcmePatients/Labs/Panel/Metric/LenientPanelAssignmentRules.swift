import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient panel assignment must pass. Check returns its problems, or none.
    protocol LenientPanelAssignmentRule {
        func check(_ item: LenientPanelAssignment) -> [String]
    }

    final class LenientPanelAssignmentCountryLengthRule: LenientPanelAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientPanelAssignment) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientPanelAssignmentCodeLengthRule: LenientPanelAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientPanelAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientPanelAssignmentRequiredCountryRule: LenientPanelAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientPanelAssignment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientPanelAssignmentRequiredCodeRule: LenientPanelAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientPanelAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientPanelAssignmentAllowedCodeRule: LenientPanelAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientPanelAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient panel assignment.
    final class LenientPanelAssignmentValidator {
        var rules: [any LenientPanelAssignmentRule]

        init(rules: [any LenientPanelAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientPanelAssignment) -> [String] {
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

        func requireValid(_ item: LenientPanelAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientPanelAssignment]) -> [String: [String]] {
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

    static func defaultLenientPanelAssignmentValidator() -> LenientPanelAssignmentValidator {
        return LenientPanelAssignmentValidator(
            rules: [
                LenientPanelAssignmentCountryLengthRule(maxLength: 1000),
                LenientPanelAssignmentCodeLengthRule(maxLength: 64),
                LenientPanelAssignmentRequiredCountryRule(message: "lenient panel assignment needs an entry"),
                LenientPanelAssignmentRequiredCodeRule(message: "lenient panel assignment needs an entry"),
                LenientPanelAssignmentAllowedCodeRule(allowed: ["seasonal"]),
            ]
        )
    }
}
