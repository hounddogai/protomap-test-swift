import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary credential ledger must pass. Check returns its problems, or none.
    protocol PrimaryCredentialLedgerRule {
        func check(_ item: PrimaryCredentialLedger) -> [String]
    }

    final class PrimaryCredentialLedgerAllowedCodeRule: PrimaryCredentialLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryCredentialLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class PrimaryCredentialLedgerMaximumRangeRule: PrimaryCredentialLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCredentialLedger) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryCredentialLedgerNameLengthRule: PrimaryCredentialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCredentialLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCredentialLedgerWeightRangeRule: PrimaryCredentialLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCredentialLedger) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryCredentialLedgerCodeLengthRule: PrimaryCredentialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCredentialLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCredentialLedgerMinimumRangeRule: PrimaryCredentialLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCredentialLedger) -> [String] {
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

    /// Runs every rule of a primary credential ledger.
    final class PrimaryCredentialLedgerValidator {
        var rules: [any PrimaryCredentialLedgerRule]

        init(rules: [any PrimaryCredentialLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCredentialLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryCredentialLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCredentialLedger]) -> [String: [String]] {
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

    static func defaultPrimaryCredentialLedgerValidator() -> PrimaryCredentialLedgerValidator {
        return PrimaryCredentialLedgerValidator(
            rules: [
                PrimaryCredentialLedgerAllowedCodeRule(allowed: ["default", "seasonal", "capped"]),
                PrimaryCredentialLedgerMaximumRangeRule(min: 8.8, max: 1261.3),
                PrimaryCredentialLedgerNameLengthRule(maxLength: 32),
                PrimaryCredentialLedgerWeightRangeRule(min: 2.2, max: 4480.3),
                PrimaryCredentialLedgerCodeLengthRule(maxLength: 16),
                PrimaryCredentialLedgerMinimumRangeRule(min: 7.8, max: 1907.2),
            ]
        )
    }
}
