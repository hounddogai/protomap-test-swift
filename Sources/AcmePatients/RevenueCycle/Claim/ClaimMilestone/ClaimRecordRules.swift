import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim record must pass. Check returns its problems, or none.
    protocol ClaimRecordRule {
        func check(_ item: ClaimRecord) -> [String]
    }

    final class ClaimRecordNameLengthRule: ClaimRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimRecordExpiresAtRangeRule: ClaimRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimRecord) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimRecordRequiredCodeRule: ClaimRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimRecordRequiredPayerRule: ClaimRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimRecord) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimRecordAllowedCodeRule: ClaimRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ClaimRecordCodePrefixRule: ClaimRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim record.
    final class ClaimRecordValidator {
        var rules: [any ClaimRecordRule]

        init(rules: [any ClaimRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimRecord) -> [String] {
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

        func requireValid(_ item: ClaimRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimRecord]) -> [String: [String]] {
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

    static func defaultClaimRecordValidator() -> ClaimRecordValidator {
        return ClaimRecordValidator(
            rules: [
                ClaimRecordNameLengthRule(maxLength: 3600),
                ClaimRecordExpiresAtRangeRule(min: 120, max: 3600),
                ClaimRecordRequiredCodeRule(message: "claim record needs an entry"),
                ClaimRecordRequiredPayerRule(message: "claim record needs a value"),
                ClaimRecordAllowedCodeRule(allowed: []),
                ClaimRecordCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
