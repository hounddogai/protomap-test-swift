import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance digest must pass. Check returns its problems, or none.
    protocol RemittanceDigestRule {
        func check(_ item: RemittanceDigest) -> [String]
    }

    final class RemittanceDigestCodeLengthRule: RemittanceDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceDigestRequiredCodeRule: RemittanceDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceDigestRequiredChannelRule: RemittanceDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceDigest) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceDigestRequiredTimezoneRule: RemittanceDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceDigest) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceDigestTimezoneLengthRule: RemittanceDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceDigest) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance digest.
    final class RemittanceDigestValidator {
        var rules: [any RemittanceDigestRule]

        init(rules: [any RemittanceDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceDigest) -> [String] {
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

        func requireValid(_ item: RemittanceDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceDigest]) -> [String: [String]] {
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

    static func defaultRemittanceDigestValidator() -> RemittanceDigestValidator {
        return RemittanceDigestValidator(
            rules: [
                RemittanceDigestCodeLengthRule(maxLength: 120),
                RemittanceDigestRequiredCodeRule(message: "remittance digest needs an entry"),
                RemittanceDigestRequiredChannelRule(message: "remittance digest needs an entry"),
                RemittanceDigestRequiredTimezoneRule(message: "remittance digest needs an entry"),
                RemittanceDigestTimezoneLengthRule(maxLength: 86400),
            ]
        )
    }
}
