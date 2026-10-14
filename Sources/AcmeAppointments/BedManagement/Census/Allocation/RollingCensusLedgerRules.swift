import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling census ledger must pass. Check returns its problems, or none.
    protocol RollingCensusLedgerRule {
        func check(_ item: RollingCensusLedger) -> [String]
    }

    final class RollingCensusLedgerWindowDaysRangeRule: RollingCensusLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCensusLedger) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCensusLedgerRequiredNameRule: RollingCensusLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCensusLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCensusLedgerPinnedGuardRule: RollingCensusLedgerRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingCensusLedger) -> [String] {
            if item.pinned && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RollingCensusLedgerGraceDaysRangeRule: RollingCensusLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCensusLedger) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCensusLedgerCodeLengthRule: RollingCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCensusLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCensusLedgerNameLengthRule: RollingCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCensusLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling census ledger.
    final class RollingCensusLedgerValidator {
        var rules: [any RollingCensusLedgerRule]

        init(rules: [any RollingCensusLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCensusLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCensusLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCensusLedger]) -> [String: [String]] {
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

    static func defaultRollingCensusLedgerValidator() -> RollingCensusLedgerValidator {
        return RollingCensusLedgerValidator(
            rules: [
                RollingCensusLedgerWindowDaysRangeRule(min: 32, max: 255),
                RollingCensusLedgerRequiredNameRule(message: "rolling census ledger needs this field"),
                RollingCensusLedgerPinnedGuardRule(limit: 2.6),
                RollingCensusLedgerGraceDaysRangeRule(min: 16, max: 255),
                RollingCensusLedgerCodeLengthRule(maxLength: 1000),
                RollingCensusLedgerNameLengthRule(maxLength: 80),
            ]
        )
    }
}
