import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen snapshot must pass. Check returns its problems, or none.
    protocol SpecimenSnapshotRule {
        func check(_ item: SpecimenSnapshot) -> [String]
    }

    final class SpecimenSnapshotActiveGuardRule: SpecimenSnapshotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SpecimenSnapshot) -> [String] {
            if item.active && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class SpecimenSnapshotCurrencyLengthRule: SpecimenSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenSnapshot) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenSnapshotCodeLengthRule: SpecimenSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenSnapshotCodePrefixRule: SpecimenSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SpecimenSnapshotTagsLimitRule: SpecimenSnapshotRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: SpecimenSnapshot) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class SpecimenSnapshotRequiredCodeRule: SpecimenSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen snapshot.
    final class SpecimenSnapshotValidator {
        var rules: [any SpecimenSnapshotRule]

        init(rules: [any SpecimenSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenSnapshot) -> [String] {
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

        func requireValid(_ item: SpecimenSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenSnapshot]) -> [String: [String]] {
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

    static func defaultSpecimenSnapshotValidator() -> SpecimenSnapshotValidator {
        return SpecimenSnapshotValidator(
            rules: [
                SpecimenSnapshotActiveGuardRule(limit: 120),
                SpecimenSnapshotCurrencyLengthRule(maxLength: 86400),
                SpecimenSnapshotCodeLengthRule(maxLength: 255),
                SpecimenSnapshotCodePrefixRule(prefix: "REF"),
                SpecimenSnapshotTagsLimitRule(maxCount: 16, banned: ["manual"]),
                SpecimenSnapshotRequiredCodeRule(message: "specimen snapshot needs a value"),
            ]
        )
    }
}
