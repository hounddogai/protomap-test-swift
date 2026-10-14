import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient care protocol claim must pass. Check returns its problems, or none.
    protocol LenientCareProtocolClaimRule {
        func check(_ item: LenientCareProtocolClaim) -> [String]
    }

    final class LenientCareProtocolClaimCodeLengthRule: LenientCareProtocolClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareProtocolClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareProtocolClaimAllowedLabelRule: LenientCareProtocolClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientCareProtocolClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class LenientCareProtocolClaimCodePrefixRule: LenientCareProtocolClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientCareProtocolClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient care protocol claim.
    final class LenientCareProtocolClaimValidator {
        var rules: [any LenientCareProtocolClaimRule]

        init(rules: [any LenientCareProtocolClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareProtocolClaim) -> [String] {
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

        func requireValid(_ item: LenientCareProtocolClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareProtocolClaim]) -> [String: [String]] {
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

    static func defaultLenientCareProtocolClaimValidator() -> LenientCareProtocolClaimValidator {
        return LenientCareProtocolClaimValidator(
            rules: [
                LenientCareProtocolClaimCodeLengthRule(maxLength: 1000),
                LenientCareProtocolClaimAllowedLabelRule(allowed: ["rolling", "tiered", "adaptive"]),
                LenientCareProtocolClaimCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
