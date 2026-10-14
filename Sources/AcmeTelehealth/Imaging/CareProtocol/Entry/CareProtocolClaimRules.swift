import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol claim must pass. Check returns its problems, or none.
    protocol CareProtocolClaimRule {
        func check(_ item: CareProtocolClaim) -> [String]
    }

    final class CareProtocolClaimGraceDaysRangeRule: CareProtocolClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolClaim) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolClaimRequiredSourceRule: CareProtocolClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolClaim) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolClaimCodePrefixRule: CareProtocolClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolClaimRequiredCodeRule: CareProtocolClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolClaimTitleLengthRule: CareProtocolClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol claim.
    final class CareProtocolClaimValidator {
        var rules: [any CareProtocolClaimRule]

        init(rules: [any CareProtocolClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolClaim) -> [String] {
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

        func requireValid(_ item: CareProtocolClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolClaim]) -> [String: [String]] {
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

    static func defaultCareProtocolClaimValidator() -> CareProtocolClaimValidator {
        return CareProtocolClaimValidator(
            rules: [
                CareProtocolClaimGraceDaysRangeRule(min: 120, max: 86400),
                CareProtocolClaimRequiredSourceRule(message: "care protocol claim needs this field"),
                CareProtocolClaimCodePrefixRule(prefix: "REF"),
                CareProtocolClaimRequiredCodeRule(message: "care protocol claim needs an entry"),
                CareProtocolClaimTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
