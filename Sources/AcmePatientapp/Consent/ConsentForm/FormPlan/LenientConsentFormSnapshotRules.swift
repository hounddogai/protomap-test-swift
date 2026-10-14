import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient consent form snapshot must pass. Check returns its problems, or none.
    protocol LenientConsentFormSnapshotRule {
        func check(_ item: LenientConsentFormSnapshot) -> [String]
    }

    final class LenientConsentFormSnapshotCostRangeRule: LenientConsentFormSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientConsentFormSnapshot) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientConsentFormSnapshotQuantityRangeRule: LenientConsentFormSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientConsentFormSnapshot) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientConsentFormSnapshotRequiredTitleRule: LenientConsentFormSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientConsentFormSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientConsentFormSnapshotTitleLengthRule: LenientConsentFormSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientConsentFormSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient consent form snapshot.
    final class LenientConsentFormSnapshotValidator {
        var rules: [any LenientConsentFormSnapshotRule]

        init(rules: [any LenientConsentFormSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientConsentFormSnapshot) -> [String] {
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

        func requireValid(_ item: LenientConsentFormSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientConsentFormSnapshot]) -> [String: [String]] {
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

    static func defaultLenientConsentFormSnapshotValidator() -> LenientConsentFormSnapshotValidator {
        return LenientConsentFormSnapshotValidator(
            rules: [
                LenientConsentFormSnapshotCostRangeRule(min: 5.5, max: 4270.9),
                LenientConsentFormSnapshotQuantityRangeRule(min: 64, max: 3600),
                LenientConsentFormSnapshotRequiredTitleRule(message: "lenient consent form snapshot needs an entry"),
                LenientConsentFormSnapshotTitleLengthRule(maxLength: 3600),
            ]
        )
    }
}
