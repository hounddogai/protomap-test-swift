import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global handoff request must pass. Check returns its problems, or none.
    protocol GlobalHandoffRequestRule {
        func check(_ item: GlobalHandoffRequest) -> [String]
    }

    final class GlobalHandoffRequestCodeLengthRule: GlobalHandoffRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalHandoffRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalHandoffRequestExpiresAtRangeRule: GlobalHandoffRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalHandoffRequest) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalHandoffRequestRequiredLabelRule: GlobalHandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalHandoffRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global handoff request.
    final class GlobalHandoffRequestValidator {
        var rules: [any GlobalHandoffRequestRule]

        init(rules: [any GlobalHandoffRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalHandoffRequest) -> [String] {
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

        func requireValid(_ item: GlobalHandoffRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalHandoffRequest]) -> [String: [String]] {
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

    static func defaultGlobalHandoffRequestValidator() -> GlobalHandoffRequestValidator {
        return GlobalHandoffRequestValidator(
            rules: [
                GlobalHandoffRequestCodeLengthRule(maxLength: 255),
                GlobalHandoffRequestExpiresAtRangeRule(min: 16, max: 32),
                GlobalHandoffRequestRequiredLabelRule(message: "global handoff request needs an entry"),
            ]
        )
    }
}
