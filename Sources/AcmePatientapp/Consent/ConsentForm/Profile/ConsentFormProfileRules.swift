import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form profile must pass. Check returns its problems, or none.
    protocol ConsentFormProfileRule {
        func check(_ item: ConsentFormProfile) -> [String]
    }

    final class ConsentFormProfileAllowedSourceRule: ConsentFormProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is not allowed"]
            }
            return []
        }
    }

    final class ConsentFormProfileRequiredSourceRule: ConsentFormProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormProfile) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormProfileRequiredCodeRule: ConsentFormProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormProfileCodeLengthRule: ConsentFormProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form profile.
    final class ConsentFormProfileValidator {
        var rules: [any ConsentFormProfileRule]

        init(rules: [any ConsentFormProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormProfile) -> [String] {
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

        func requireValid(_ item: ConsentFormProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormProfile]) -> [String: [String]] {
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

    static func defaultConsentFormProfileValidator() -> ConsentFormProfileValidator {
        return ConsentFormProfileValidator(
            rules: [
                ConsentFormProfileAllowedSourceRule(allowed: ["global"]),
                ConsentFormProfileRequiredSourceRule(message: "consent form profile needs a value"),
                ConsentFormProfileRequiredCodeRule(message: "consent form profile needs a value"),
                ConsentFormProfileCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
