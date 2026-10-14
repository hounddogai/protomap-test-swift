import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary slot snapshot must pass. Check returns its problems, or none.
    protocol PrimarySlotSnapshotRule {
        func check(_ item: PrimarySlotSnapshot) -> [String]
    }

    final class PrimarySlotSnapshotQuantityRangeRule: PrimarySlotSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySlotSnapshot) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimarySlotSnapshotExternalRefLengthRule: PrimarySlotSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySlotSnapshot) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySlotSnapshotRequiredExternalRefRule: PrimarySlotSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySlotSnapshot) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySlotSnapshotUnitLengthRule: PrimarySlotSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySlotSnapshot) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySlotSnapshotAllowedCodeRule: PrimarySlotSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimarySlotSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a primary slot snapshot.
    final class PrimarySlotSnapshotValidator {
        var rules: [any PrimarySlotSnapshotRule]

        init(rules: [any PrimarySlotSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySlotSnapshot) -> [String] {
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

        func requireValid(_ item: PrimarySlotSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySlotSnapshot]) -> [String: [String]] {
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

    static func defaultPrimarySlotSnapshotValidator() -> PrimarySlotSnapshotValidator {
        return PrimarySlotSnapshotValidator(
            rules: [
                PrimarySlotSnapshotQuantityRangeRule(min: 80, max: 3600),
                PrimarySlotSnapshotExternalRefLengthRule(maxLength: 16),
                PrimarySlotSnapshotRequiredExternalRefRule(message: "primary slot snapshot needs this field"),
                PrimarySlotSnapshotUnitLengthRule(maxLength: 120),
                PrimarySlotSnapshotAllowedCodeRule(allowed: ["capped"]),
            ]
        )
    }
}
