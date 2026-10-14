import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped revocation bundle must pass. Check returns its problems, or none.
    protocol CappedRevocationBundleRule {
        func check(_ item: CappedRevocationBundle) -> [String]
    }

    final class CappedRevocationBundleCodePrefixRule: CappedRevocationBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRevocationBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedRevocationBundleRequiredCodeRule: CappedRevocationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRevocationBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRevocationBundleRequiredNameRule: CappedRevocationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRevocationBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRevocationBundleCodeLengthRule: CappedRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRevocationBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped revocation bundle.
    final class CappedRevocationBundleValidator {
        var rules: [any CappedRevocationBundleRule]

        init(rules: [any CappedRevocationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRevocationBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedRevocationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRevocationBundle]) -> [String: [String]] {
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

    static func defaultCappedRevocationBundleValidator() -> CappedRevocationBundleValidator {
        return CappedRevocationBundleValidator(
            rules: [
                CappedRevocationBundleCodePrefixRule(prefix: "Q"),
                CappedRevocationBundleRequiredCodeRule(message: "capped revocation bundle needs an entry"),
                CappedRevocationBundleRequiredNameRule(message: "capped revocation bundle needs this field"),
                CappedRevocationBundleCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
