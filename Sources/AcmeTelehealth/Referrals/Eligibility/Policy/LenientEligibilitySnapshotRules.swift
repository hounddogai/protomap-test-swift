import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient eligibility snapshot must pass. Check returns its problems, or none.
    protocol LenientEligibilitySnapshotRule {
        func check(_ item: LenientEligibilitySnapshot) -> [String]
    }

    final class LenientEligibilitySnapshotCopayRangeRule: LenientEligibilitySnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientEligibilitySnapshot) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientEligibilitySnapshotRequiredLabelRule: LenientEligibilitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientEligibilitySnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientEligibilitySnapshotAllowedNameRule: LenientEligibilitySnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientEligibilitySnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class LenientEligibilitySnapshotLabelLengthRule: LenientEligibilitySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientEligibilitySnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient eligibility snapshot.
    final class LenientEligibilitySnapshotValidator {
        var rules: [any LenientEligibilitySnapshotRule]

        init(rules: [any LenientEligibilitySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientEligibilitySnapshot) -> [String] {
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

        func requireValid(_ item: LenientEligibilitySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientEligibilitySnapshot]) -> [String: [String]] {
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

    static func defaultLenientEligibilitySnapshotValidator() -> LenientEligibilitySnapshotValidator {
        return LenientEligibilitySnapshotValidator(
            rules: [
                LenientEligibilitySnapshotCopayRangeRule(min: 8.1, max: 2330.8),
                LenientEligibilitySnapshotRequiredLabelRule(message: "lenient eligibility snapshot needs this field"),
                LenientEligibilitySnapshotAllowedNameRule(allowed: []),
                LenientEligibilitySnapshotLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
