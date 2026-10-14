import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary closure bundle must pass. Check returns its problems, or none.
    protocol PrimaryClosureBundleRule {
        func check(_ item: PrimaryClosureBundle) -> [String]
    }

    final class PrimaryClosureBundlePayerLengthRule: PrimaryClosureBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClosureBundle) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryClosureBundleCodePrefixRule: PrimaryClosureBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryClosureBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryClosureBundleRequiredCodeRule: PrimaryClosureBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryClosureBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryClosureBundleCodeLengthRule: PrimaryClosureBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClosureBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary closure bundle.
    final class PrimaryClosureBundleValidator {
        var rules: [any PrimaryClosureBundleRule]

        init(rules: [any PrimaryClosureBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryClosureBundle) -> [String] {
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

        func requireValid(_ item: PrimaryClosureBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryClosureBundle]) -> [String: [String]] {
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

    static func defaultPrimaryClosureBundleValidator() -> PrimaryClosureBundleValidator {
        return PrimaryClosureBundleValidator(
            rules: [
                PrimaryClosureBundlePayerLengthRule(maxLength: 3600),
                PrimaryClosureBundleCodePrefixRule(prefix: "Q"),
                PrimaryClosureBundleRequiredCodeRule(message: "primary closure bundle needs an entry"),
                PrimaryClosureBundleCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
