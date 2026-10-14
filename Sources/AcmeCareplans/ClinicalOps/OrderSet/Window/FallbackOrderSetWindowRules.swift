import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback order set window must pass. Check returns its problems, or none.
    protocol FallbackOrderSetWindowRule {
        func check(_ item: FallbackOrderSetWindow) -> [String]
    }

    final class FallbackOrderSetWindowCodePrefixRule: FallbackOrderSetWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackOrderSetWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackOrderSetWindowRequiredEncounterIDRule: FallbackOrderSetWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetWindow) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOrderSetWindowRequiredLabelRule: FallbackOrderSetWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback order set window.
    final class FallbackOrderSetWindowValidator {
        var rules: [any FallbackOrderSetWindowRule]

        init(rules: [any FallbackOrderSetWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOrderSetWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackOrderSetWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOrderSetWindow]) -> [String: [String]] {
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

    static func defaultFallbackOrderSetWindowValidator() -> FallbackOrderSetWindowValidator {
        return FallbackOrderSetWindowValidator(
            rules: [
                FallbackOrderSetWindowCodePrefixRule(prefix: "Q"),
                FallbackOrderSetWindowRequiredEncounterIDRule(message: "fallback order set window needs this field"),
                FallbackOrderSetWindowRequiredLabelRule(message: "fallback order set window needs an entry"),
            ]
        )
    }
}
