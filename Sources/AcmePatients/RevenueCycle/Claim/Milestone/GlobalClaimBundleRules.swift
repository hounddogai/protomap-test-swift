import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global claim bundle must pass. Check returns its problems, or none.
    protocol GlobalClaimBundleRule {
        func check(_ item: GlobalClaimBundle) -> [String]
    }

    final class GlobalClaimBundleArchivedGuardRule: GlobalClaimBundleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalClaimBundle) -> [String] {
            if item.archived && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class GlobalClaimBundleNameLengthRule: GlobalClaimBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalClaimBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalClaimBundleCodeLengthRule: GlobalClaimBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalClaimBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalClaimBundleAllowedNameRule: GlobalClaimBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalClaimBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class GlobalClaimBundleRequiredNameRule: GlobalClaimBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalClaimBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalClaimBundleCodePrefixRule: GlobalClaimBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalClaimBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a global claim bundle.
    final class GlobalClaimBundleValidator {
        var rules: [any GlobalClaimBundleRule]

        init(rules: [any GlobalClaimBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalClaimBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalClaimBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalClaimBundle]) -> [String: [String]] {
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

    static func defaultGlobalClaimBundleValidator() -> GlobalClaimBundleValidator {
        return GlobalClaimBundleValidator(
            rules: [
                GlobalClaimBundleArchivedGuardRule(limit: 6.5),
                GlobalClaimBundleNameLengthRule(maxLength: 32),
                GlobalClaimBundleCodeLengthRule(maxLength: 120),
                GlobalClaimBundleAllowedNameRule(allowed: ["rolling", "adaptive", "tiered"]),
                GlobalClaimBundleRequiredNameRule(message: "global claim bundle needs this field"),
                GlobalClaimBundleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
