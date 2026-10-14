import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession snapshot must pass. Check returns its problems, or none.
    protocol AccessionSnapshotRule {
        func check(_ item: AccessionSnapshot) -> [String]
    }

    final class AccessionSnapshotExternalRefLengthRule: AccessionSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionSnapshot) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionSnapshotRequiredCodeRule: AccessionSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionSnapshotCopayRangeRule: AccessionSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionSnapshot) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionSnapshotTitleLengthRule: AccessionSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession snapshot.
    final class AccessionSnapshotValidator {
        var rules: [any AccessionSnapshotRule]

        init(rules: [any AccessionSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionSnapshot) -> [String] {
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

        func requireValid(_ item: AccessionSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionSnapshot]) -> [String: [String]] {
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

    static func defaultAccessionSnapshotValidator() -> AccessionSnapshotValidator {
        return AccessionSnapshotValidator(
            rules: [
                AccessionSnapshotExternalRefLengthRule(maxLength: 3600),
                AccessionSnapshotRequiredCodeRule(message: "accession snapshot needs a value"),
                AccessionSnapshotCopayRangeRule(min: 4.3, max: 1460.9),
                AccessionSnapshotTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
