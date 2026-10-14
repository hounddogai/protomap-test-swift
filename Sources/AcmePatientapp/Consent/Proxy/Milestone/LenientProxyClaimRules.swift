import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy claim must pass. Check returns its problems, or none.
    protocol LenientProxyClaimRule {
        func check(_ item: LenientProxyClaim) -> [String]
    }

    final class LenientProxyClaimRequiredNameRule: LenientProxyClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyClaimNameLengthRule: LenientProxyClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxyClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProxyClaimBudgetRangeRule: LenientProxyClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxyClaim) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientProxyClaimCodePrefixRule: LenientProxyClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientProxyClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientProxyClaimRequiredCodeRule: LenientProxyClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyClaimWardLengthRule: LenientProxyClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxyClaim) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient proxy claim.
    final class LenientProxyClaimValidator {
        var rules: [any LenientProxyClaimRule]

        init(rules: [any LenientProxyClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxyClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientProxyClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxyClaim]) -> [String: [String]] {
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

    static func defaultLenientProxyClaimValidator() -> LenientProxyClaimValidator {
        return LenientProxyClaimValidator(
            rules: [
                LenientProxyClaimRequiredNameRule(message: "lenient proxy claim needs this field"),
                LenientProxyClaimNameLengthRule(maxLength: 86400),
                LenientProxyClaimBudgetRangeRule(min: 6.5, max: 4427.9),
                LenientProxyClaimCodePrefixRule(prefix: "ACM"),
                LenientProxyClaimRequiredCodeRule(message: "lenient proxy claim needs an entry"),
                LenientProxyClaimWardLengthRule(maxLength: 32),
            ]
        )
    }
}
