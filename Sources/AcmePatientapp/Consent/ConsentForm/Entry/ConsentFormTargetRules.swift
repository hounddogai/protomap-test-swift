import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form target must pass. Check returns its problems, or none.
    protocol ConsentFormTargetRule {
        func check(_ item: ConsentFormTarget) -> [String]
    }

    final class ConsentFormTargetLocaleLengthRule: ConsentFormTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormTarget) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormTargetRequiredCodeRule: ConsentFormTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormTargetRequiredLocaleRule: ConsentFormTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormTarget) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormTargetCodeLengthRule: ConsentFormTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form target.
    final class ConsentFormTargetValidator {
        var rules: [any ConsentFormTargetRule]

        init(rules: [any ConsentFormTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormTarget) -> [String] {
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

        func requireValid(_ item: ConsentFormTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormTarget]) -> [String: [String]] {
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

    static func defaultConsentFormTargetValidator() -> ConsentFormTargetValidator {
        return ConsentFormTargetValidator(
            rules: [
                ConsentFormTargetLocaleLengthRule(maxLength: 16),
                ConsentFormTargetRequiredCodeRule(message: "consent form target needs an entry"),
                ConsentFormTargetRequiredLocaleRule(message: "consent form target needs a value"),
                ConsentFormTargetCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
