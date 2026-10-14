import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime draft must pass. Check returns its problems, or none.
    protocol OvertimeDraftRule {
        func check(_ item: OvertimeDraft) -> [String]
    }

    final class OvertimeDraftRequiredAllergyRule: OvertimeDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeDraft) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeDraftLabelLengthRule: OvertimeDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeDraftRequiredCodeRule: OvertimeDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeDraftAllowedCodeRule: OvertimeDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime draft.
    final class OvertimeDraftValidator {
        var rules: [any OvertimeDraftRule]

        init(rules: [any OvertimeDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeDraft]) -> [String: [String]] {
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

    static func defaultOvertimeDraftValidator() -> OvertimeDraftValidator {
        return OvertimeDraftValidator(
            rules: [
                OvertimeDraftRequiredAllergyRule(message: "overtime draft needs this field"),
                OvertimeDraftLabelLengthRule(maxLength: 120),
                OvertimeDraftRequiredCodeRule(message: "overtime draft needs this field"),
                OvertimeDraftAllowedCodeRule(allowed: ["global", "strict"]),
            ]
        )
    }
}
