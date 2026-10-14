import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient float pool variance must pass. Check returns its problems, or none.
    protocol LenientFloatPoolVarianceRule {
        func check(_ item: LenientFloatPoolVariance) -> [String]
    }

    final class LenientFloatPoolVarianceCodePrefixRule: LenientFloatPoolVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientFloatPoolVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientFloatPoolVarianceAllowedReviewerRule: LenientFloatPoolVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientFloatPoolVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is below minimum"]
            }
            return []
        }
    }

    final class LenientFloatPoolVarianceRequiredTitleRule: LenientFloatPoolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientFloatPoolVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientFloatPoolVarianceFacilityLengthRule: LenientFloatPoolVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientFloatPoolVariance) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientFloatPoolVarianceRequiredFacilityRule: LenientFloatPoolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientFloatPoolVariance) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientFloatPoolVarianceCodeLengthRule: LenientFloatPoolVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientFloatPoolVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient float pool variance.
    final class LenientFloatPoolVarianceValidator {
        var rules: [any LenientFloatPoolVarianceRule]

        init(rules: [any LenientFloatPoolVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientFloatPoolVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientFloatPoolVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientFloatPoolVariance]) -> [String: [String]] {
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

    static func defaultLenientFloatPoolVarianceValidator() -> LenientFloatPoolVarianceValidator {
        return LenientFloatPoolVarianceValidator(
            rules: [
                LenientFloatPoolVarianceCodePrefixRule(prefix: "Q"),
                LenientFloatPoolVarianceAllowedReviewerRule(allowed: ["tiered"]),
                LenientFloatPoolVarianceRequiredTitleRule(message: "lenient float pool variance needs an entry"),
                LenientFloatPoolVarianceFacilityLengthRule(maxLength: 16),
                LenientFloatPoolVarianceRequiredFacilityRule(message: "lenient float pool variance needs an entry"),
                LenientFloatPoolVarianceCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
