import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback result ledger must pass. Check returns its problems, or none.
    protocol FallbackResultLedgerRule {
        func check(_ item: FallbackResultLedger) -> [String]
    }

    final class FallbackResultLedgerNameLengthRule: FallbackResultLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackResultLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackResultLedgerExternalRefLengthRule: FallbackResultLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackResultLedger) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackResultLedgerAllowedNameRule: FallbackResultLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackResultLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class FallbackResultLedgerRequiredSpecialtyRule: FallbackResultLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackResultLedger) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackResultLedgerRequiredCodeRule: FallbackResultLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackResultLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback result ledger.
    final class FallbackResultLedgerValidator {
        var rules: [any FallbackResultLedgerRule]

        init(rules: [any FallbackResultLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackResultLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackResultLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackResultLedger]) -> [String: [String]] {
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

    static func defaultFallbackResultLedgerValidator() -> FallbackResultLedgerValidator {
        return FallbackResultLedgerValidator(
            rules: [
                FallbackResultLedgerNameLengthRule(maxLength: 86400),
                FallbackResultLedgerExternalRefLengthRule(maxLength: 16),
                FallbackResultLedgerAllowedNameRule(allowed: ["manual", "capped", "default"]),
                FallbackResultLedgerRequiredSpecialtyRule(message: "fallback result ledger needs this field"),
                FallbackResultLedgerRequiredCodeRule(message: "fallback result ledger needs a value"),
            ]
        )
    }
}
