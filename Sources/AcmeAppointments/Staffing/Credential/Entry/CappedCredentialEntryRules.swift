import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped credential entry must pass. Check returns its problems, or none.
    protocol CappedCredentialEntryRule {
        func check(_ item: CappedCredentialEntry) -> [String]
    }

    final class CappedCredentialEntryAmountRangeRule: CappedCredentialEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCredentialEntry) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedCredentialEntryRequiredCategoryRule: CappedCredentialEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCredentialEntry) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCredentialEntryThresholdRangeRule: CappedCredentialEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCredentialEntry) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedCredentialEntryCodeLengthRule: CappedCredentialEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCredentialEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCredentialEntryAllowedChecksumRule: CappedCredentialEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCredentialEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a capped credential entry.
    final class CappedCredentialEntryValidator {
        var rules: [any CappedCredentialEntryRule]

        init(rules: [any CappedCredentialEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCredentialEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCredentialEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCredentialEntry]) -> [String: [String]] {
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

    static func defaultCappedCredentialEntryValidator() -> CappedCredentialEntryValidator {
        return CappedCredentialEntryValidator(
            rules: [
                CappedCredentialEntryAmountRangeRule(min: 5.1, max: 1794.0),
                CappedCredentialEntryRequiredCategoryRule(message: "capped credential entry needs a value"),
                CappedCredentialEntryThresholdRangeRule(min: 6.9, max: 1901.6),
                CappedCredentialEntryCodeLengthRule(maxLength: 32),
                CappedCredentialEntryAllowedChecksumRule(allowed: []),
            ]
        )
    }
}
