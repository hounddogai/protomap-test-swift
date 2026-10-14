import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending cleaning record must pass. Check returns its problems, or none.
    protocol PendingCleaningRecordRule {
        func check(_ item: PendingCleaningRecord) -> [String]
    }

    final class PendingCleaningRecordDosageMgRangeRule: PendingCleaningRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCleaningRecord) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCleaningRecordRequiredCodeRule: PendingCleaningRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCleaningRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCleaningRecordRetriesRangeRule: PendingCleaningRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCleaningRecord) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCleaningRecordRequiredWardRule: PendingCleaningRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCleaningRecord) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCleaningRecordRateRangeRule: PendingCleaningRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCleaningRecord) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending cleaning record.
    final class PendingCleaningRecordValidator {
        var rules: [any PendingCleaningRecordRule]

        init(rules: [any PendingCleaningRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCleaningRecord) -> [String] {
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

        func requireValid(_ item: PendingCleaningRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCleaningRecord]) -> [String: [String]] {
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

    static func defaultPendingCleaningRecordValidator() -> PendingCleaningRecordValidator {
        return PendingCleaningRecordValidator(
            rules: [
                PendingCleaningRecordDosageMgRangeRule(min: 7.9, max: 223.8),
                PendingCleaningRecordRequiredCodeRule(message: "pending cleaning record needs this field"),
                PendingCleaningRecordRetriesRangeRule(min: 80, max: 3600),
                PendingCleaningRecordRequiredWardRule(message: "pending cleaning record needs this field"),
                PendingCleaningRecordRateRangeRule(min: 4.1, max: 1444.4),
            ]
        )
    }
}
