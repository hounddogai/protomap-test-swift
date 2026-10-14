import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped consent form notice must pass. Check returns its problems, or none.
    protocol CappedConsentFormNoticeRule {
        func check(_ item: CappedConsentFormNotice) -> [String]
    }

    final class CappedConsentFormNoticeCodePrefixRule: CappedConsentFormNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedConsentFormNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedConsentFormNoticeAllowedCodeRule: CappedConsentFormNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedConsentFormNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class CappedConsentFormNoticeAttemptsRangeRule: CappedConsentFormNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedConsentFormNotice) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped consent form notice.
    final class CappedConsentFormNoticeValidator {
        var rules: [any CappedConsentFormNoticeRule]

        init(rules: [any CappedConsentFormNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedConsentFormNotice) -> [String] {
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

        func requireValid(_ item: CappedConsentFormNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedConsentFormNotice]) -> [String: [String]] {
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

    static func defaultCappedConsentFormNoticeValidator() -> CappedConsentFormNoticeValidator {
        return CappedConsentFormNoticeValidator(
            rules: [
                CappedConsentFormNoticeCodePrefixRule(prefix: "X"),
                CappedConsentFormNoticeAllowedCodeRule(allowed: ["manual"]),
                CappedConsentFormNoticeAttemptsRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
