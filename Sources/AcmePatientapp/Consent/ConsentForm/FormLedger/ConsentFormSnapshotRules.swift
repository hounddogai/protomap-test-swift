import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form snapshot must pass. Check returns its problems, or none.
    protocol ConsentFormSnapshotRule {
        func check(_ item: ConsentFormSnapshot) -> [String]
    }

    final class ConsentFormSnapshotTagsLimitRule: ConsentFormSnapshotRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ConsentFormSnapshot) -> [String] {
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

    final class ConsentFormSnapshotCodeLengthRule: ConsentFormSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormSnapshotRequiredCodeRule: ConsentFormSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormSnapshotCategoryLengthRule: ConsentFormSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSnapshot) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form snapshot.
    final class ConsentFormSnapshotValidator {
        var rules: [any ConsentFormSnapshotRule]

        init(rules: [any ConsentFormSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormSnapshot]) -> [String: [String]] {
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

    static func defaultConsentFormSnapshotValidator() -> ConsentFormSnapshotValidator {
        return ConsentFormSnapshotValidator(
            rules: [
                ConsentFormSnapshotTagsLimitRule(maxCount: 3600, banned: []),
                ConsentFormSnapshotCodeLengthRule(maxLength: 64),
                ConsentFormSnapshotRequiredCodeRule(message: "consent form snapshot needs this field"),
                ConsentFormSnapshotCategoryLengthRule(maxLength: 32),
            ]
        )
    }
}
