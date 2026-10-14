import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient language checkpoint must pass. Check returns its problems, or none.
    protocol LenientLanguageCheckpointRule {
        func check(_ item: LenientLanguageCheckpoint) -> [String]
    }

    final class LenientLanguageCheckpointRequiredDescriptionRule: LenientLanguageCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientLanguageCheckpoint) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientLanguageCheckpointRequiredChecksumRule: LenientLanguageCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientLanguageCheckpoint) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientLanguageCheckpointRequiredCodeRule: LenientLanguageCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientLanguageCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient language checkpoint.
    final class LenientLanguageCheckpointValidator {
        var rules: [any LenientLanguageCheckpointRule]

        init(rules: [any LenientLanguageCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientLanguageCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientLanguageCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientLanguageCheckpoint]) -> [String: [String]] {
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

    static func defaultLenientLanguageCheckpointValidator() -> LenientLanguageCheckpointValidator {
        return LenientLanguageCheckpointValidator(
            rules: [
                LenientLanguageCheckpointRequiredDescriptionRule(message: "lenient language checkpoint needs a value"),
                LenientLanguageCheckpointRequiredChecksumRule(message: "lenient language checkpoint needs a value"),
                LenientLanguageCheckpointRequiredCodeRule(message: "lenient language checkpoint needs this field"),
            ]
        )
    }
}
