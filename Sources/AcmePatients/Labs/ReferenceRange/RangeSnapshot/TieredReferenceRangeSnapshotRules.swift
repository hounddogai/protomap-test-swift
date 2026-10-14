import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered reference range snapshot must pass. Check returns its problems, or none.
    protocol TieredReferenceRangeSnapshotRule {
        func check(_ item: TieredReferenceRangeSnapshot) -> [String]
    }

    final class TieredReferenceRangeSnapshotAmountRangeRule: TieredReferenceRangeSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReferenceRangeSnapshot) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredReferenceRangeSnapshotContactEmailLengthRule: TieredReferenceRangeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferenceRangeSnapshot) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferenceRangeSnapshotRequiredCodeRule: TieredReferenceRangeSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferenceRangeSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferenceRangeSnapshotAllowedCodeRule: TieredReferenceRangeSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredReferenceRangeSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class TieredReferenceRangeSnapshotLabelLengthRule: TieredReferenceRangeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferenceRangeSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered reference range snapshot.
    final class TieredReferenceRangeSnapshotValidator {
        var rules: [any TieredReferenceRangeSnapshotRule]

        init(rules: [any TieredReferenceRangeSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReferenceRangeSnapshot) -> [String] {
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

        func requireValid(_ item: TieredReferenceRangeSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReferenceRangeSnapshot]) -> [String: [String]] {
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

    static func defaultTieredReferenceRangeSnapshotValidator() -> TieredReferenceRangeSnapshotValidator {
        return TieredReferenceRangeSnapshotValidator(
            rules: [
                TieredReferenceRangeSnapshotAmountRangeRule(min: 4.9, max: 3755.0),
                TieredReferenceRangeSnapshotContactEmailLengthRule(maxLength: 80),
                TieredReferenceRangeSnapshotRequiredCodeRule(
                    message: "tiered reference range snapshot needs an entry"
                ),
                TieredReferenceRangeSnapshotAllowedCodeRule(allowed: ["pending", "batched", "seasonal"]),
                TieredReferenceRangeSnapshotLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
