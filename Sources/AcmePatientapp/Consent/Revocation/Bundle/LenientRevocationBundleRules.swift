import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient revocation bundle must pass. Check returns its problems, or none.
    protocol LenientRevocationBundleRule {
        func check(_ item: LenientRevocationBundle) -> [String]
    }

    final class LenientRevocationBundleAllowedContactEmailRule: LenientRevocationBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRevocationBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is duplicated"]
            }
            return []
        }
    }

    final class LenientRevocationBundleContactEmailLengthRule: LenientRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRevocationBundle) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRevocationBundleCodePrefixRule: LenientRevocationBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientRevocationBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientRevocationBundleRefillsRangeRule: LenientRevocationBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRevocationBundle) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRevocationBundleAllergyLengthRule: LenientRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRevocationBundle) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient revocation bundle.
    final class LenientRevocationBundleValidator {
        var rules: [any LenientRevocationBundleRule]

        init(rules: [any LenientRevocationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRevocationBundle) -> [String] {
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

        func requireValid(_ item: LenientRevocationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRevocationBundle]) -> [String: [String]] {
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

    static func defaultLenientRevocationBundleValidator() -> LenientRevocationBundleValidator {
        return LenientRevocationBundleValidator(
            rules: [
                LenientRevocationBundleAllowedContactEmailRule(allowed: []),
                LenientRevocationBundleContactEmailLengthRule(maxLength: 86400),
                LenientRevocationBundleCodePrefixRule(prefix: "ACM"),
                LenientRevocationBundleRefillsRangeRule(min: 80, max: 86400),
                LenientRevocationBundleAllergyLengthRule(maxLength: 80),
            ]
        )
    }
}
