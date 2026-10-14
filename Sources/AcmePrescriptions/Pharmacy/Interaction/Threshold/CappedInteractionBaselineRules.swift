import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped interaction baseline must pass. Check returns its problems, or none.
    protocol CappedInteractionBaselineRule {
        func check(_ item: CappedInteractionBaseline) -> [String]
    }

    final class CappedInteractionBaselineRequiredExternalRefRule: CappedInteractionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedInteractionBaseline) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedInteractionBaselineExternalRefLengthRule: CappedInteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedInteractionBaseline) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedInteractionBaselineRevisionRangeRule: CappedInteractionBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedInteractionBaseline) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedInteractionBaselineAllowedCodeRule: CappedInteractionBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedInteractionBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class CappedInteractionBaselineCodeLengthRule: CappedInteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedInteractionBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedInteractionBaselineRequiredCodeRule: CappedInteractionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedInteractionBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped interaction baseline.
    final class CappedInteractionBaselineValidator {
        var rules: [any CappedInteractionBaselineRule]

        init(rules: [any CappedInteractionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedInteractionBaseline) -> [String] {
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

        func requireValid(_ item: CappedInteractionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedInteractionBaseline]) -> [String: [String]] {
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

    static func defaultCappedInteractionBaselineValidator() -> CappedInteractionBaselineValidator {
        return CappedInteractionBaselineValidator(
            rules: [
                CappedInteractionBaselineRequiredExternalRefRule(message: "capped interaction baseline needs a value"),
                CappedInteractionBaselineExternalRefLengthRule(maxLength: 120),
                CappedInteractionBaselineRevisionRangeRule(min: 80, max: 3600),
                CappedInteractionBaselineAllowedCodeRule(allowed: ["primary", "global"]),
                CappedInteractionBaselineCodeLengthRule(maxLength: 1000),
                CappedInteractionBaselineRequiredCodeRule(message: "capped interaction baseline needs this field"),
            ]
        )
    }
}
