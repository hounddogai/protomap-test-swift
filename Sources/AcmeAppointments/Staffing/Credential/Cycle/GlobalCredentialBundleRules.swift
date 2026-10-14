import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global credential bundle must pass. Check returns its problems, or none.
    protocol GlobalCredentialBundleRule {
        func check(_ item: GlobalCredentialBundle) -> [String]
    }

    final class GlobalCredentialBundleCodePrefixRule: GlobalCredentialBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCredentialBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCredentialBundleRequiredLabelRule: GlobalCredentialBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCredentialBundleCodeLengthRule: GlobalCredentialBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCredentialBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCredentialBundleRequiredFacilityRule: GlobalCredentialBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialBundle) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCredentialBundleNameLengthRule: GlobalCredentialBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCredentialBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global credential bundle.
    final class GlobalCredentialBundleValidator {
        var rules: [any GlobalCredentialBundleRule]

        init(rules: [any GlobalCredentialBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCredentialBundle) -> [String] {
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

        func requireValid(_ item: GlobalCredentialBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCredentialBundle]) -> [String: [String]] {
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

    static func defaultGlobalCredentialBundleValidator() -> GlobalCredentialBundleValidator {
        return GlobalCredentialBundleValidator(
            rules: [
                GlobalCredentialBundleCodePrefixRule(prefix: "ACM"),
                GlobalCredentialBundleRequiredLabelRule(message: "global credential bundle needs a value"),
                GlobalCredentialBundleCodeLengthRule(maxLength: 255),
                GlobalCredentialBundleRequiredFacilityRule(message: "global credential bundle needs an entry"),
                GlobalCredentialBundleNameLengthRule(maxLength: 255),
            ]
        )
    }
}
