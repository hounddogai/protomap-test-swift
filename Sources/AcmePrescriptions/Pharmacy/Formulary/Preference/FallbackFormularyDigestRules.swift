import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback formulary digest must pass. Check returns its problems, or none.
    protocol FallbackFormularyDigestRule {
        func check(_ item: FallbackFormularyDigest) -> [String]
    }

    final class FallbackFormularyDigestCodeLengthRule: FallbackFormularyDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackFormularyDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackFormularyDigestCodePrefixRule: FallbackFormularyDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackFormularyDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackFormularyDigestRequiredSpecialtyRule: FallbackFormularyDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFormularyDigest) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackFormularyDigestRequiredNameRule: FallbackFormularyDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFormularyDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback formulary digest.
    final class FallbackFormularyDigestValidator {
        var rules: [any FallbackFormularyDigestRule]

        init(rules: [any FallbackFormularyDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFormularyDigest) -> [String] {
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

        func requireValid(_ item: FallbackFormularyDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFormularyDigest]) -> [String: [String]] {
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

    static func defaultFallbackFormularyDigestValidator() -> FallbackFormularyDigestValidator {
        return FallbackFormularyDigestValidator(
            rules: [
                FallbackFormularyDigestCodeLengthRule(maxLength: 86400),
                FallbackFormularyDigestCodePrefixRule(prefix: "ACM"),
                FallbackFormularyDigestRequiredSpecialtyRule(message: "fallback formulary digest needs this field"),
                FallbackFormularyDigestRequiredNameRule(message: "fallback formulary digest needs this field"),
            ]
        )
    }
}
