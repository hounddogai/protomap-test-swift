import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read agreement must pass. Check returns its problems, or none.
    protocol ReadAgreementRule {
        func check(_ item: ReadAgreement) -> [String]
    }

    final class ReadAgreementCodeLengthRule: ReadAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadAgreementCodePrefixRule: ReadAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReadAgreementAllowedUnitRule: ReadAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a read agreement.
    final class ReadAgreementValidator {
        var rules: [any ReadAgreementRule]

        init(rules: [any ReadAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadAgreement) -> [String] {
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

        func requireValid(_ item: ReadAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadAgreement]) -> [String: [String]] {
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

    static func defaultReadAgreementValidator() -> ReadAgreementValidator {
        return ReadAgreementValidator(
            rules: [
                ReadAgreementCodeLengthRule(maxLength: 86400),
                ReadAgreementCodePrefixRule(prefix: "REF"),
                ReadAgreementAllowedUnitRule(allowed: ["default"]),
            ]
        )
    }
}
