import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted disclosure snapshot must pass. Check returns its problems, or none.
    protocol WeightedDisclosureSnapshotRule {
        func check(_ item: WeightedDisclosureSnapshot) -> [String]
    }

    final class WeightedDisclosureSnapshotRequiredReviewerRule: WeightedDisclosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDisclosureSnapshot) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedDisclosureSnapshotWeightRangeRule: WeightedDisclosureSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedDisclosureSnapshot) -> [String] {
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

    final class WeightedDisclosureSnapshotLocaleLengthRule: WeightedDisclosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDisclosureSnapshot) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDisclosureSnapshotAllowedLabelRule: WeightedDisclosureSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedDisclosureSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted disclosure snapshot.
    final class WeightedDisclosureSnapshotValidator {
        var rules: [any WeightedDisclosureSnapshotRule]

        init(rules: [any WeightedDisclosureSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDisclosureSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedDisclosureSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDisclosureSnapshot]) -> [String: [String]] {
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

    static func defaultWeightedDisclosureSnapshotValidator() -> WeightedDisclosureSnapshotValidator {
        return WeightedDisclosureSnapshotValidator(
            rules: [
                WeightedDisclosureSnapshotRequiredReviewerRule(message: "weighted disclosure snapshot needs an entry"),
                WeightedDisclosureSnapshotWeightRangeRule(min: 3.5, max: 4391.3),
                WeightedDisclosureSnapshotLocaleLengthRule(maxLength: 32),
                WeightedDisclosureSnapshotAllowedLabelRule(allowed: ["primary"]),
            ]
        )
    }
}
