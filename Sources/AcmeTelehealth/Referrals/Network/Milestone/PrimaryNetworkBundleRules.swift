import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary network bundle must pass. Check returns its problems, or none.
    protocol PrimaryNetworkBundleRule {
        func check(_ item: PrimaryNetworkBundle) -> [String]
    }

    final class PrimaryNetworkBundleAllowedBedRule: PrimaryNetworkBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryNetworkBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is out of range"]
            }
            return []
        }
    }

    final class PrimaryNetworkBundleRequiredNameRule: PrimaryNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryNetworkBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryNetworkBundleNameLengthRule: PrimaryNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryNetworkBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryNetworkBundleCodeLengthRule: PrimaryNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryNetworkBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary network bundle.
    final class PrimaryNetworkBundleValidator {
        var rules: [any PrimaryNetworkBundleRule]

        init(rules: [any PrimaryNetworkBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryNetworkBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryNetworkBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryNetworkBundle]) -> [String: [String]] {
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

    static func defaultPrimaryNetworkBundleValidator() -> PrimaryNetworkBundleValidator {
        return PrimaryNetworkBundleValidator(
            rules: [
                PrimaryNetworkBundleAllowedBedRule(allowed: []),
                PrimaryNetworkBundleRequiredNameRule(message: "primary network bundle needs this field"),
                PrimaryNetworkBundleNameLengthRule(maxLength: 32),
                PrimaryNetworkBundleCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
