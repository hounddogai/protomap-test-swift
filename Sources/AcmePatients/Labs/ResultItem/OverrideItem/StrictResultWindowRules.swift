import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict result window must pass. Check returns its problems, or none.
    protocol StrictResultWindowRule {
        func check(_ item: StrictResultWindow) -> [String]
    }

    final class StrictResultWindowCodeLengthRule: StrictResultWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictResultWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictResultWindowRequiredCodeRule: StrictResultWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictResultWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictResultWindowAllowedClinicianIDRule: StrictResultWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictResultWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is out of range"]
            }
            return []
        }
    }

    final class StrictResultWindowRequiredNameRule: StrictResultWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictResultWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict result window.
    final class StrictResultWindowValidator {
        var rules: [any StrictResultWindowRule]

        init(rules: [any StrictResultWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictResultWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictResultWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictResultWindow]) -> [String: [String]] {
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

    static func defaultStrictResultWindowValidator() -> StrictResultWindowValidator {
        return StrictResultWindowValidator(
            rules: [
                StrictResultWindowCodeLengthRule(maxLength: 86400),
                StrictResultWindowRequiredCodeRule(message: "strict result window needs an entry"),
                StrictResultWindowAllowedClinicianIDRule(allowed: ["pending"]),
                StrictResultWindowRequiredNameRule(message: "strict result window needs a value"),
            ]
        )
    }
}
