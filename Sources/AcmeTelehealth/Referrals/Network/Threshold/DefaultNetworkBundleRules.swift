import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default network bundle must pass. Check returns its problems, or none.
    protocol DefaultNetworkBundleRule {
        func check(_ item: DefaultNetworkBundle) -> [String]
    }

    final class DefaultNetworkBundleCodeLengthRule: DefaultNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultNetworkBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultNetworkBundleSourceLengthRule: DefaultNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultNetworkBundle) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultNetworkBundleCategoryLengthRule: DefaultNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultNetworkBundle) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultNetworkBundleRequiredCodeRule: DefaultNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultNetworkBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultNetworkBundleRequiredTitleRule: DefaultNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultNetworkBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultNetworkBundleAllowedCategoryRule: DefaultNetworkBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultNetworkBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a default network bundle.
    final class DefaultNetworkBundleValidator {
        var rules: [any DefaultNetworkBundleRule]

        init(rules: [any DefaultNetworkBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultNetworkBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultNetworkBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultNetworkBundle]) -> [String: [String]] {
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

    static func defaultDefaultNetworkBundleValidator() -> DefaultNetworkBundleValidator {
        return DefaultNetworkBundleValidator(
            rules: [
                DefaultNetworkBundleCodeLengthRule(maxLength: 16),
                DefaultNetworkBundleSourceLengthRule(maxLength: 3600),
                DefaultNetworkBundleCategoryLengthRule(maxLength: 86400),
                DefaultNetworkBundleRequiredCodeRule(message: "default network bundle needs a value"),
                DefaultNetworkBundleRequiredTitleRule(message: "default network bundle needs a value"),
                DefaultNetworkBundleAllowedCategoryRule(allowed: []),
            ]
        )
    }
}
