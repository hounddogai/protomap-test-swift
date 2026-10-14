import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff variance must pass. Check returns its problems, or none.
    protocol HandoffVarianceRule {
        func check(_ item: HandoffVariance) -> [String]
    }

    final class HandoffVarianceRequiredExternalRefRule: HandoffVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffVariance) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffVarianceRequiredCodeRule: HandoffVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffVarianceRequiredLabelRule: HandoffVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffVarianceCodePrefixRule: HandoffVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffVarianceExternalRefLengthRule: HandoffVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffVariance) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff variance.
    final class HandoffVarianceValidator {
        var rules: [any HandoffVarianceRule]

        init(rules: [any HandoffVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffVariance) -> [String] {
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

        func requireValid(_ item: HandoffVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffVariance]) -> [String: [String]] {
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

    static func defaultHandoffVarianceValidator() -> HandoffVarianceValidator {
        return HandoffVarianceValidator(
            rules: [
                HandoffVarianceRequiredExternalRefRule(message: "handoff variance needs an entry"),
                HandoffVarianceRequiredCodeRule(message: "handoff variance needs a value"),
                HandoffVarianceRequiredLabelRule(message: "handoff variance needs a value"),
                HandoffVarianceCodePrefixRule(prefix: "OPS"),
                HandoffVarianceExternalRefLengthRule(maxLength: 1000),
            ]
        )
    }
}
