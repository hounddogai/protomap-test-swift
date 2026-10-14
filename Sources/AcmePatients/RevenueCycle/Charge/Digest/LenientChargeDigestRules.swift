import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient charge digest must pass. Check returns its problems, or none.
    protocol LenientChargeDigestRule {
        func check(_ item: LenientChargeDigest) -> [String]
    }

    final class LenientChargeDigestCodePrefixRule: LenientChargeDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientChargeDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientChargeDigestOwnerIDLengthRule: LenientChargeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientChargeDigest) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientChargeDigestRequiredLabelRule: LenientChargeDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientChargeDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientChargeDigestRequiredOwnerIDRule: LenientChargeDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientChargeDigest) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient charge digest.
    final class LenientChargeDigestValidator {
        var rules: [any LenientChargeDigestRule]

        init(rules: [any LenientChargeDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientChargeDigest) -> [String] {
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

        func requireValid(_ item: LenientChargeDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientChargeDigest]) -> [String: [String]] {
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

    static func defaultLenientChargeDigestValidator() -> LenientChargeDigestValidator {
        return LenientChargeDigestValidator(
            rules: [
                LenientChargeDigestCodePrefixRule(prefix: "OPS"),
                LenientChargeDigestOwnerIDLengthRule(maxLength: 86400),
                LenientChargeDigestRequiredLabelRule(message: "lenient charge digest needs a value"),
                LenientChargeDigestRequiredOwnerIDRule(message: "lenient charge digest needs this field"),
            ]
        )
    }
}
