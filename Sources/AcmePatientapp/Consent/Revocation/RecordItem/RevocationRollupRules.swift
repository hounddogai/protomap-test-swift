import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation rollup must pass. Check returns its problems, or none.
    protocol RevocationRollupRule {
        func check(_ item: RevocationRollup) -> [String]
    }

    final class RevocationRollupRequiredCodeRule: RevocationRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationRollupCodePrefixRule: RevocationRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RevocationRollupOwnerIDLengthRule: RevocationRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationRollup) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationRollupMinimumRangeRule: RevocationRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationRollup) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a revocation rollup.
    final class RevocationRollupValidator {
        var rules: [any RevocationRollupRule]

        init(rules: [any RevocationRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationRollup]) -> [String: [String]] {
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

    static func defaultRevocationRollupValidator() -> RevocationRollupValidator {
        return RevocationRollupValidator(
            rules: [
                RevocationRollupRequiredCodeRule(message: "revocation rollup needs an entry"),
                RevocationRollupCodePrefixRule(prefix: "OPS"),
                RevocationRollupOwnerIDLengthRule(maxLength: 32),
                RevocationRollupMinimumRangeRule(min: 2.4, max: 3552.7),
            ]
        )
    }
}
