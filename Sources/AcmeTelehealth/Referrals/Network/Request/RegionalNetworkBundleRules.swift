import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional network bundle must pass. Check returns its problems, or none.
    protocol RegionalNetworkBundleRule {
        func check(_ item: RegionalNetworkBundle) -> [String]
    }

    final class RegionalNetworkBundleCodePrefixRule: RegionalNetworkBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalNetworkBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalNetworkBundleProcedureCodeLengthRule: RegionalNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalNetworkBundle) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalNetworkBundleRequiredCodeRule: RegionalNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalNetworkBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional network bundle.
    final class RegionalNetworkBundleValidator {
        var rules: [any RegionalNetworkBundleRule]

        init(rules: [any RegionalNetworkBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalNetworkBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalNetworkBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalNetworkBundle]) -> [String: [String]] {
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

    static func defaultRegionalNetworkBundleValidator() -> RegionalNetworkBundleValidator {
        return RegionalNetworkBundleValidator(
            rules: [
                RegionalNetworkBundleCodePrefixRule(prefix: "ACM"),
                RegionalNetworkBundleProcedureCodeLengthRule(maxLength: 80),
                RegionalNetworkBundleRequiredCodeRule(message: "regional network bundle needs this field"),
            ]
        )
    }
}
