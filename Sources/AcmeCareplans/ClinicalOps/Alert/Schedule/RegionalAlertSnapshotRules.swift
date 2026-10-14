import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional alert snapshot must pass. Check returns its problems, or none.
    protocol RegionalAlertSnapshotRule {
        func check(_ item: RegionalAlertSnapshot) -> [String]
    }

    final class RegionalAlertSnapshotRequiredContactEmailRule: RegionalAlertSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAlertSnapshot) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAlertSnapshotCostRangeRule: RegionalAlertSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAlertSnapshot) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalAlertSnapshotContactEmailLengthRule: RegionalAlertSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAlertSnapshot) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAlertSnapshotAllowedLabelRule: RegionalAlertSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalAlertSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class RegionalAlertSnapshotCodePrefixRule: RegionalAlertSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalAlertSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalAlertSnapshotCodeLengthRule: RegionalAlertSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAlertSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional alert snapshot.
    final class RegionalAlertSnapshotValidator {
        var rules: [any RegionalAlertSnapshotRule]

        init(rules: [any RegionalAlertSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAlertSnapshot) -> [String] {
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

        func requireValid(_ item: RegionalAlertSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAlertSnapshot]) -> [String: [String]] {
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

    static func defaultRegionalAlertSnapshotValidator() -> RegionalAlertSnapshotValidator {
        return RegionalAlertSnapshotValidator(
            rules: [
                RegionalAlertSnapshotRequiredContactEmailRule(message: "regional alert snapshot needs a value"),
                RegionalAlertSnapshotCostRangeRule(min: 7.8, max: 1681.7),
                RegionalAlertSnapshotContactEmailLengthRule(maxLength: 80),
                RegionalAlertSnapshotAllowedLabelRule(allowed: []),
                RegionalAlertSnapshotCodePrefixRule(prefix: "ACM"),
                RegionalAlertSnapshotCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
