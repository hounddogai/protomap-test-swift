import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered slot snapshot must pass. Check returns its problems, or none.
    protocol TieredSlotSnapshotRule {
        func check(_ item: TieredSlotSnapshot) -> [String]
    }

    final class TieredSlotSnapshotReviewerLengthRule: TieredSlotSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSlotSnapshot) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSlotSnapshotAcuityRangeRule: TieredSlotSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSlotSnapshot) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredSlotSnapshotNameLengthRule: TieredSlotSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSlotSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSlotSnapshotCodePrefixRule: TieredSlotSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredSlotSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredSlotSnapshotTimezoneLengthRule: TieredSlotSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSlotSnapshot) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered slot snapshot.
    final class TieredSlotSnapshotValidator {
        var rules: [any TieredSlotSnapshotRule]

        init(rules: [any TieredSlotSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSlotSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredSlotSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSlotSnapshot]) -> [String: [String]] {
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

    static func defaultTieredSlotSnapshotValidator() -> TieredSlotSnapshotValidator {
        return TieredSlotSnapshotValidator(
            rules: [
                TieredSlotSnapshotReviewerLengthRule(maxLength: 16),
                TieredSlotSnapshotAcuityRangeRule(min: 32, max: 255),
                TieredSlotSnapshotNameLengthRule(maxLength: 80),
                TieredSlotSnapshotCodePrefixRule(prefix: "ACM"),
                TieredSlotSnapshotTimezoneLengthRule(maxLength: 3600),
            ]
        )
    }
}
