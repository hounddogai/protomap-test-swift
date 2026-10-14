import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation policy must pass. Check returns its problems, or none.
    protocol RevocationPolicyRule {
        func check(_ item: RevocationPolicy) -> [String]
    }

    final class RevocationPolicySegmentLengthRule: RevocationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationPolicy) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationPolicyDiscountRangeRule: RevocationPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationPolicy) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RevocationPolicyCodePrefixRule: RevocationPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RevocationPolicyRequiredSegmentRule: RevocationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationPolicy) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation policy.
    final class RevocationPolicyValidator {
        var rules: [any RevocationPolicyRule]

        init(rules: [any RevocationPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationPolicy) -> [String] {
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

        func requireValid(_ item: RevocationPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationPolicy]) -> [String: [String]] {
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

    static func defaultRevocationPolicyValidator() -> RevocationPolicyValidator {
        return RevocationPolicyValidator(
            rules: [
                RevocationPolicySegmentLengthRule(maxLength: 3600),
                RevocationPolicyDiscountRangeRule(min: 8.9, max: 2879.7),
                RevocationPolicyCodePrefixRule(prefix: "REF"),
                RevocationPolicyRequiredSegmentRule(message: "revocation policy needs an entry"),
            ]
        )
    }
}
