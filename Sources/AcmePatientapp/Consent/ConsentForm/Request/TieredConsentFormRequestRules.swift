import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered consent form request must pass. Check returns its problems, or none.
    protocol TieredConsentFormRequestRule {
        func check(_ item: TieredConsentFormRequest) -> [String]
    }

    final class TieredConsentFormRequestCodePrefixRule: TieredConsentFormRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredConsentFormRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredConsentFormRequestLocaleLengthRule: TieredConsentFormRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredConsentFormRequest) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredConsentFormRequestAllowedLocaleRule: TieredConsentFormRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredConsentFormRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is missing"]
            }
            return []
        }
    }

    final class TieredConsentFormRequestBatchSizeRangeRule: TieredConsentFormRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredConsentFormRequest) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered consent form request.
    final class TieredConsentFormRequestValidator {
        var rules: [any TieredConsentFormRequestRule]

        init(rules: [any TieredConsentFormRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredConsentFormRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredConsentFormRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredConsentFormRequest]) -> [String: [String]] {
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

    static func defaultTieredConsentFormRequestValidator() -> TieredConsentFormRequestValidator {
        return TieredConsentFormRequestValidator(
            rules: [
                TieredConsentFormRequestCodePrefixRule(prefix: "REF"),
                TieredConsentFormRequestLocaleLengthRule(maxLength: 255),
                TieredConsentFormRequestAllowedLocaleRule(allowed: ["rolling", "seasonal", "regional"]),
                TieredConsentFormRequestBatchSizeRangeRule(min: 32, max: 255),
            ]
        )
    }
}
