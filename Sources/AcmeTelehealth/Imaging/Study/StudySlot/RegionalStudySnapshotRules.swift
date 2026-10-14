import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional study snapshot must pass. Check returns its problems, or none.
    protocol RegionalStudySnapshotRule {
        func check(_ item: RegionalStudySnapshot) -> [String]
    }

    final class RegionalStudySnapshotRequiredLabelRule: RegionalStudySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStudySnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStudySnapshotLabelLengthRule: RegionalStudySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStudySnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStudySnapshotCodeLengthRule: RegionalStudySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStudySnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStudySnapshotRequiredNameRule: RegionalStudySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStudySnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStudySnapshotRequiredCodeRule: RegionalStudySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStudySnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional study snapshot.
    final class RegionalStudySnapshotValidator {
        var rules: [any RegionalStudySnapshotRule]

        init(rules: [any RegionalStudySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStudySnapshot) -> [String] {
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

        func requireValid(_ item: RegionalStudySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStudySnapshot]) -> [String: [String]] {
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

    static func defaultRegionalStudySnapshotValidator() -> RegionalStudySnapshotValidator {
        return RegionalStudySnapshotValidator(
            rules: [
                RegionalStudySnapshotRequiredLabelRule(message: "regional study snapshot needs an entry"),
                RegionalStudySnapshotLabelLengthRule(maxLength: 1000),
                RegionalStudySnapshotCodeLengthRule(maxLength: 86400),
                RegionalStudySnapshotRequiredNameRule(message: "regional study snapshot needs this field"),
                RegionalStudySnapshotRequiredCodeRule(message: "regional study snapshot needs a value"),
            ]
        )
    }
}
