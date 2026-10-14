import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy draft must pass. Check returns its problems, or none.
    protocol LenientProxyDraftRule {
        func check(_ item: LenientProxyDraft) -> [String]
    }

    final class LenientProxyDraftRetriesRangeRule: LenientProxyDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxyDraft) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientProxyDraftThresholdRangeRule: LenientProxyDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxyDraft) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientProxyDraftRequiredLocaleRule: LenientProxyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyDraft) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyDraftCodeLengthRule: LenientProxyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxyDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient proxy draft.
    final class LenientProxyDraftValidator {
        var rules: [any LenientProxyDraftRule]

        init(rules: [any LenientProxyDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxyDraft) -> [String] {
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

        func requireValid(_ item: LenientProxyDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxyDraft]) -> [String: [String]] {
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

    static func defaultLenientProxyDraftValidator() -> LenientProxyDraftValidator {
        return LenientProxyDraftValidator(
            rules: [
                LenientProxyDraftRetriesRangeRule(min: 255, max: 255),
                LenientProxyDraftThresholdRangeRule(min: 9.0, max: 3178.4),
                LenientProxyDraftRequiredLocaleRule(message: "lenient proxy draft needs a value"),
                LenientProxyDraftCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
