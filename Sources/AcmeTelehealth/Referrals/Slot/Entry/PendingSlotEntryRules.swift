import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending slot entry must pass. Check returns its problems, or none.
    protocol PendingSlotEntryRule {
        func check(_ item: PendingSlotEntry) -> [String]
    }

    final class PendingSlotEntryScoreRangeRule: PendingSlotEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSlotEntry) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingSlotEntryRequiredPayerRule: PendingSlotEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSlotEntry) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSlotEntryRequiredClinicianIDRule: PendingSlotEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSlotEntry) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending slot entry.
    final class PendingSlotEntryValidator {
        var rules: [any PendingSlotEntryRule]

        init(rules: [any PendingSlotEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSlotEntry) -> [String] {
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

        func requireValid(_ item: PendingSlotEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSlotEntry]) -> [String: [String]] {
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

    static func defaultPendingSlotEntryValidator() -> PendingSlotEntryValidator {
        return PendingSlotEntryValidator(
            rules: [
                PendingSlotEntryScoreRangeRule(min: 2.1, max: 2242.7),
                PendingSlotEntryRequiredPayerRule(message: "pending slot entry needs a value"),
                PendingSlotEntryRequiredClinicianIDRule(message: "pending slot entry needs an entry"),
            ]
        )
    }
}
