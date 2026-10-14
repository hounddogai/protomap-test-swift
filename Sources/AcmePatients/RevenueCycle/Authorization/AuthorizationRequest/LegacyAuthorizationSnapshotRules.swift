import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy authorization snapshot must pass. Check returns its problems, or none.
    protocol LegacyAuthorizationSnapshotRule {
        func check(_ item: LegacyAuthorizationSnapshot) -> [String]
    }

    final class LegacyAuthorizationSnapshotRequiredLabelRule: LegacyAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAuthorizationSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAuthorizationSnapshotThresholdRangeRule: LegacyAuthorizationSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAuthorizationSnapshot) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyAuthorizationSnapshotRefillsRangeRule: LegacyAuthorizationSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAuthorizationSnapshot) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy authorization snapshot.
    final class LegacyAuthorizationSnapshotValidator {
        var rules: [any LegacyAuthorizationSnapshotRule]

        init(rules: [any LegacyAuthorizationSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAuthorizationSnapshot) -> [String] {
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

        func requireValid(_ item: LegacyAuthorizationSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAuthorizationSnapshot]) -> [String: [String]] {
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

    static func defaultLegacyAuthorizationSnapshotValidator() -> LegacyAuthorizationSnapshotValidator {
        return LegacyAuthorizationSnapshotValidator(
            rules: [
                LegacyAuthorizationSnapshotRequiredLabelRule(
                    message: "legacy authorization snapshot needs this field"
                ),
                LegacyAuthorizationSnapshotThresholdRangeRule(min: 1.5, max: 2722.1),
                LegacyAuthorizationSnapshotRefillsRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
