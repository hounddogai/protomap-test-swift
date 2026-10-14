import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback modality quota must pass. Check returns its problems, or none.
    protocol FallbackModalityQuotaRule {
        func check(_ item: FallbackModalityQuota) -> [String]
    }

    final class FallbackModalityQuotaRequiredCodeRule: FallbackModalityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackModalityQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackModalityQuotaRequiredTimezoneRule: FallbackModalityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackModalityQuota) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackModalityQuotaTimezoneLengthRule: FallbackModalityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackModalityQuota) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackModalityQuotaRequiredNameRule: FallbackModalityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackModalityQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackModalityQuotaAllowedTimezoneRule: FallbackModalityQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackModalityQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback modality quota.
    final class FallbackModalityQuotaValidator {
        var rules: [any FallbackModalityQuotaRule]

        init(rules: [any FallbackModalityQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackModalityQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackModalityQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackModalityQuota]) -> [String: [String]] {
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

    static func defaultFallbackModalityQuotaValidator() -> FallbackModalityQuotaValidator {
        return FallbackModalityQuotaValidator(
            rules: [
                FallbackModalityQuotaRequiredCodeRule(message: "fallback modality quota needs an entry"),
                FallbackModalityQuotaRequiredTimezoneRule(message: "fallback modality quota needs an entry"),
                FallbackModalityQuotaTimezoneLengthRule(maxLength: 86400),
                FallbackModalityQuotaRequiredNameRule(message: "fallback modality quota needs this field"),
                FallbackModalityQuotaAllowedTimezoneRule(allowed: []),
            ]
        )
    }
}
