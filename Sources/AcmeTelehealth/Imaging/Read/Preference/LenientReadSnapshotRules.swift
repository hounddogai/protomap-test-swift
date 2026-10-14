import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient read snapshot must pass. Check returns its problems, or none.
    protocol LenientReadSnapshotRule {
        func check(_ item: LenientReadSnapshot) -> [String]
    }

    final class LenientReadSnapshotStartsAtRangeRule: LenientReadSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReadSnapshot) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientReadSnapshotLocaleLengthRule: LenientReadSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReadSnapshot) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientReadSnapshotTitleLengthRule: LenientReadSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReadSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient read snapshot.
    final class LenientReadSnapshotValidator {
        var rules: [any LenientReadSnapshotRule]

        init(rules: [any LenientReadSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReadSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientReadSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReadSnapshot]) -> [String: [String]] {
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

    static func defaultLenientReadSnapshotValidator() -> LenientReadSnapshotValidator {
        return LenientReadSnapshotValidator(
            rules: [
                LenientReadSnapshotStartsAtRangeRule(min: 1000, max: 1000),
                LenientReadSnapshotLocaleLengthRule(maxLength: 16),
                LenientReadSnapshotTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
