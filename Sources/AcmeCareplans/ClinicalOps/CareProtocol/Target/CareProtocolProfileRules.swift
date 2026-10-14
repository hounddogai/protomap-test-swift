import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol profile must pass. Check returns its problems, or none.
    protocol CareProtocolProfileRule {
        func check(_ item: CareProtocolProfile) -> [String]
    }

    final class CareProtocolProfileRequiredLabelRule: CareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolProfileAllowedCodeRule: CareProtocolProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class CareProtocolProfileRequiredChannelRule: CareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolProfile) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolProfileRequiredCodeRule: CareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolProfileLabelLengthRule: CareProtocolProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol profile.
    final class CareProtocolProfileValidator {
        var rules: [any CareProtocolProfileRule]

        init(rules: [any CareProtocolProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolProfile]) -> [String: [String]] {
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

    static func defaultCareProtocolProfileValidator() -> CareProtocolProfileValidator {
        return CareProtocolProfileValidator(
            rules: [
                CareProtocolProfileRequiredLabelRule(message: "care protocol profile needs a value"),
                CareProtocolProfileAllowedCodeRule(allowed: []),
                CareProtocolProfileRequiredChannelRule(message: "care protocol profile needs a value"),
                CareProtocolProfileRequiredCodeRule(message: "care protocol profile needs a value"),
                CareProtocolProfileLabelLengthRule(maxLength: 1000),
            ]
        )
    }
}
