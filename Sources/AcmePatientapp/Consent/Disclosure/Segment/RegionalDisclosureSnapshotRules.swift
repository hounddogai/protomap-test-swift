import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional disclosure snapshot must pass. Check returns its problems, or none.
    protocol RegionalDisclosureSnapshotRule {
        func check(_ item: RegionalDisclosureSnapshot) -> [String]
    }

    final class RegionalDisclosureSnapshotAllowedCodeRule: RegionalDisclosureSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalDisclosureSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class RegionalDisclosureSnapshotRequiredCodeRule: RegionalDisclosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDisclosureSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDisclosureSnapshotBudgetRangeRule: RegionalDisclosureSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDisclosureSnapshot) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalDisclosureSnapshotRequiredPhoneRule: RegionalDisclosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDisclosureSnapshot) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDisclosureSnapshotUnitLengthRule: RegionalDisclosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDisclosureSnapshot) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional disclosure snapshot.
    final class RegionalDisclosureSnapshotValidator {
        var rules: [any RegionalDisclosureSnapshotRule]

        init(rules: [any RegionalDisclosureSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDisclosureSnapshot) -> [String] {
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

        func requireValid(_ item: RegionalDisclosureSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDisclosureSnapshot]) -> [String: [String]] {
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

    static func defaultRegionalDisclosureSnapshotValidator() -> RegionalDisclosureSnapshotValidator {
        return RegionalDisclosureSnapshotValidator(
            rules: [
                RegionalDisclosureSnapshotAllowedCodeRule(allowed: ["scheduled"]),
                RegionalDisclosureSnapshotRequiredCodeRule(message: "regional disclosure snapshot needs a value"),
                RegionalDisclosureSnapshotBudgetRangeRule(min: 6.6, max: 3116.5),
                RegionalDisclosureSnapshotRequiredPhoneRule(message: "regional disclosure snapshot needs an entry"),
                RegionalDisclosureSnapshotUnitLengthRule(maxLength: 120),
            ]
        )
    }
}
