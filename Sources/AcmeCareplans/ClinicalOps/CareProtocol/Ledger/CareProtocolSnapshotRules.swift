import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol snapshot must pass. Check returns its problems, or none.
    protocol CareProtocolSnapshotRule {
        func check(_ item: CareProtocolSnapshot) -> [String]
    }

    final class CareProtocolSnapshotBudgetRangeRule: CareProtocolSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolSnapshot) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolSnapshotRequiredTimezoneRule: CareProtocolSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolSnapshot) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolSnapshotRequiredCodeRule: CareProtocolSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolSnapshotNameLengthRule: CareProtocolSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolSnapshotRequiredNameRule: CareProtocolSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol snapshot.
    final class CareProtocolSnapshotValidator {
        var rules: [any CareProtocolSnapshotRule]

        init(rules: [any CareProtocolSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolSnapshot) -> [String] {
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

        func requireValid(_ item: CareProtocolSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolSnapshot]) -> [String: [String]] {
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

    static func defaultCareProtocolSnapshotValidator() -> CareProtocolSnapshotValidator {
        return CareProtocolSnapshotValidator(
            rules: [
                CareProtocolSnapshotBudgetRangeRule(min: 0.1, max: 4917.3),
                CareProtocolSnapshotRequiredTimezoneRule(message: "care protocol snapshot needs an entry"),
                CareProtocolSnapshotRequiredCodeRule(message: "care protocol snapshot needs this field"),
                CareProtocolSnapshotNameLengthRule(maxLength: 86400),
                CareProtocolSnapshotRequiredNameRule(message: "care protocol snapshot needs this field"),
            ]
        )
    }
}
