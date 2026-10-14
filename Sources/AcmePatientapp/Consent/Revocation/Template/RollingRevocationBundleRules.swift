import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling revocation bundle must pass. Check returns its problems, or none.
    protocol RollingRevocationBundleRule {
        func check(_ item: RollingRevocationBundle) -> [String]
    }

    final class RollingRevocationBundleCodePrefixRule: RollingRevocationBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingRevocationBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingRevocationBundleTitleLengthRule: RollingRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRevocationBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRevocationBundleRequiredNameRule: RollingRevocationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRevocationBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRevocationBundleRequiredCodeRule: RollingRevocationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRevocationBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling revocation bundle.
    final class RollingRevocationBundleValidator {
        var rules: [any RollingRevocationBundleRule]

        init(rules: [any RollingRevocationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRevocationBundle) -> [String] {
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

        func requireValid(_ item: RollingRevocationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRevocationBundle]) -> [String: [String]] {
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

    static func defaultRollingRevocationBundleValidator() -> RollingRevocationBundleValidator {
        return RollingRevocationBundleValidator(
            rules: [
                RollingRevocationBundleCodePrefixRule(prefix: "Q"),
                RollingRevocationBundleTitleLengthRule(maxLength: 1000),
                RollingRevocationBundleRequiredNameRule(message: "rolling revocation bundle needs this field"),
                RollingRevocationBundleRequiredCodeRule(message: "rolling revocation bundle needs an entry"),
            ]
        )
    }
}
