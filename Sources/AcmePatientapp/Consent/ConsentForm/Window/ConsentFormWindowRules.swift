import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form window must pass. Check returns its problems, or none.
    protocol ConsentFormWindowRule {
        func check(_ item: ConsentFormWindow) -> [String]
    }

    final class ConsentFormWindowLabelLengthRule: ConsentFormWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormWindowRequiredLabelRule: ConsentFormWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormWindowRequiredCodeRule: ConsentFormWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormWindowAllowedLabelRule: ConsentFormWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form window.
    final class ConsentFormWindowValidator {
        var rules: [any ConsentFormWindowRule]

        init(rules: [any ConsentFormWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormWindow]) -> [String: [String]] {
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

    static func defaultConsentFormWindowValidator() -> ConsentFormWindowValidator {
        return ConsentFormWindowValidator(
            rules: [
                ConsentFormWindowLabelLengthRule(maxLength: 86400),
                ConsentFormWindowRequiredLabelRule(message: "consent form window needs a value"),
                ConsentFormWindowRequiredCodeRule(message: "consent form window needs an entry"),
                ConsentFormWindowAllowedLabelRule(allowed: []),
            ]
        )
    }
}
