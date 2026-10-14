import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global disclosure snapshot must pass. Check returns its problems, or none.
    protocol GlobalDisclosureSnapshotRule {
        func check(_ item: GlobalDisclosureSnapshot) -> [String]
    }

    final class GlobalDisclosureSnapshotCodeLengthRule: GlobalDisclosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDisclosureSnapshotMinimumRangeRule: GlobalDisclosureSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDisclosureSnapshot) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalDisclosureSnapshotWeightRangeRule: GlobalDisclosureSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDisclosureSnapshot) -> [String] {
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

    final class GlobalDisclosureSnapshotPayerLengthRule: GlobalDisclosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureSnapshot) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDisclosureSnapshotRequiredLabelRule: GlobalDisclosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDisclosureSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDisclosureSnapshotNotesLengthRule: GlobalDisclosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureSnapshot) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global disclosure snapshot.
    final class GlobalDisclosureSnapshotValidator {
        var rules: [any GlobalDisclosureSnapshotRule]

        init(rules: [any GlobalDisclosureSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDisclosureSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalDisclosureSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDisclosureSnapshot]) -> [String: [String]] {
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

    static func defaultGlobalDisclosureSnapshotValidator() -> GlobalDisclosureSnapshotValidator {
        return GlobalDisclosureSnapshotValidator(
            rules: [
                GlobalDisclosureSnapshotCodeLengthRule(maxLength: 80),
                GlobalDisclosureSnapshotMinimumRangeRule(min: 6.6, max: 2884.5),
                GlobalDisclosureSnapshotWeightRangeRule(min: 7.3, max: 3312.5),
                GlobalDisclosureSnapshotPayerLengthRule(maxLength: 1000),
                GlobalDisclosureSnapshotRequiredLabelRule(message: "global disclosure snapshot needs an entry"),
                GlobalDisclosureSnapshotNotesLengthRule(maxLength: 1000),
            ]
        )
    }
}
