import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range snapshot must pass. Check returns its problems, or none.
    protocol ReferenceRangeSnapshotRule {
        func check(_ item: ReferenceRangeSnapshot) -> [String]
    }

    final class ReferenceRangeSnapshotTitleLengthRule: ReferenceRangeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeSnapshotRevisionRangeRule: ReferenceRangeSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeSnapshot) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeSnapshotChannelLengthRule: ReferenceRangeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSnapshot) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeSnapshotCodePrefixRule: ReferenceRangeSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range snapshot.
    final class ReferenceRangeSnapshotValidator {
        var rules: [any ReferenceRangeSnapshotRule]

        init(rules: [any ReferenceRangeSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeSnapshot) -> [String] {
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

        func requireValid(_ item: ReferenceRangeSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeSnapshot]) -> [String: [String]] {
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

    static func defaultReferenceRangeSnapshotValidator() -> ReferenceRangeSnapshotValidator {
        return ReferenceRangeSnapshotValidator(
            rules: [
                ReferenceRangeSnapshotTitleLengthRule(maxLength: 80),
                ReferenceRangeSnapshotRevisionRangeRule(min: 1000, max: 3600),
                ReferenceRangeSnapshotChannelLengthRule(maxLength: 64),
                ReferenceRangeSnapshotCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
