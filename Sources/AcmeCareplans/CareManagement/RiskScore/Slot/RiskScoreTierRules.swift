import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score tier must pass. Check returns its problems, or none.
    protocol RiskScoreTierRule {
        func check(_ item: RiskScoreTier) -> [String]
    }

    final class RiskScoreTierRequiredLabelRule: RiskScoreTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreTierCodePrefixRule: RiskScoreTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreTierLabelLengthRule: RiskScoreTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreTierChecksumLengthRule: RiskScoreTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreTier) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score tier.
    final class RiskScoreTierValidator {
        var rules: [any RiskScoreTierRule]

        init(rules: [any RiskScoreTierRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreTier]) -> [String: [String]] {
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

    static func defaultRiskScoreTierValidator() -> RiskScoreTierValidator {
        return RiskScoreTierValidator(
            rules: [
                RiskScoreTierRequiredLabelRule(message: "risk score tier needs a value"),
                RiskScoreTierCodePrefixRule(prefix: "ACM"),
                RiskScoreTierLabelLengthRule(maxLength: 32),
                RiskScoreTierChecksumLengthRule(maxLength: 16),
            ]
        )
    }
}
