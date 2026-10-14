import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global authorization bundle must pass. Check returns its problems, or none.
    protocol GlobalAuthorizationBundleRule {
        func check(_ item: GlobalAuthorizationBundle) -> [String]
    }

    final class GlobalAuthorizationBundleRequiredLabelRule: GlobalAuthorizationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAuthorizationBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAuthorizationBundleNameLengthRule: GlobalAuthorizationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAuthorizationBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAuthorizationBundleAllowedNameRule: GlobalAuthorizationBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalAuthorizationBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class GlobalAuthorizationBundleLabelLengthRule: GlobalAuthorizationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAuthorizationBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global authorization bundle.
    final class GlobalAuthorizationBundleValidator {
        var rules: [any GlobalAuthorizationBundleRule]

        init(rules: [any GlobalAuthorizationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAuthorizationBundle) -> [String] {
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

        func requireValid(_ item: GlobalAuthorizationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAuthorizationBundle]) -> [String: [String]] {
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

    static func defaultGlobalAuthorizationBundleValidator() -> GlobalAuthorizationBundleValidator {
        return GlobalAuthorizationBundleValidator(
            rules: [
                GlobalAuthorizationBundleRequiredLabelRule(message: "global authorization bundle needs an entry"),
                GlobalAuthorizationBundleNameLengthRule(maxLength: 86400),
                GlobalAuthorizationBundleAllowedNameRule(allowed: []),
                GlobalAuthorizationBundleLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
