import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation estimate must pass. Check returns its problems, or none.
    protocol RevocationEstimateRule {
        func check(_ item: RevocationEstimate) -> [String]
    }

    final class RevocationEstimateActiveGuardRule: RevocationEstimateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RevocationEstimate) -> [String] {
            if item.active && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RevocationEstimateCodePrefixRule: RevocationEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RevocationEstimateCodeLengthRule: RevocationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationEstimateNameLengthRule: RevocationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation estimate.
    final class RevocationEstimateValidator {
        var rules: [any RevocationEstimateRule]

        init(rules: [any RevocationEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationEstimate) -> [String] {
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

        func requireValid(_ item: RevocationEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationEstimate]) -> [String: [String]] {
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

    static func defaultRevocationEstimateValidator() -> RevocationEstimateValidator {
        return RevocationEstimateValidator(
            rules: [
                RevocationEstimateActiveGuardRule(limit: 0.1),
                RevocationEstimateCodePrefixRule(prefix: "ACM"),
                RevocationEstimateCodeLengthRule(maxLength: 86400),
                RevocationEstimateNameLengthRule(maxLength: 64),
            ]
        )
    }
}
