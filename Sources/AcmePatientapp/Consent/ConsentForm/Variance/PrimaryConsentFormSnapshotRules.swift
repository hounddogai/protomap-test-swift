import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary consent form snapshot must pass. Check returns its problems, or none.
    protocol PrimaryConsentFormSnapshotRule {
        func check(_ item: PrimaryConsentFormSnapshot) -> [String]
    }

    final class PrimaryConsentFormSnapshotRequiredNameRule: PrimaryConsentFormSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryConsentFormSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryConsentFormSnapshotCodePrefixRule: PrimaryConsentFormSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryConsentFormSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryConsentFormSnapshotLabelLengthRule: PrimaryConsentFormSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryConsentFormSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryConsentFormSnapshotNameLengthRule: PrimaryConsentFormSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryConsentFormSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryConsentFormSnapshotRequiredCodeRule: PrimaryConsentFormSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryConsentFormSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryConsentFormSnapshotScoreRangeRule: PrimaryConsentFormSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryConsentFormSnapshot) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary consent form snapshot.
    final class PrimaryConsentFormSnapshotValidator {
        var rules: [any PrimaryConsentFormSnapshotRule]

        init(rules: [any PrimaryConsentFormSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryConsentFormSnapshot) -> [String] {
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

        func requireValid(_ item: PrimaryConsentFormSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryConsentFormSnapshot]) -> [String: [String]] {
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

    static func defaultPrimaryConsentFormSnapshotValidator() -> PrimaryConsentFormSnapshotValidator {
        return PrimaryConsentFormSnapshotValidator(
            rules: [
                PrimaryConsentFormSnapshotRequiredNameRule(message: "primary consent form snapshot needs this field"),
                PrimaryConsentFormSnapshotCodePrefixRule(prefix: "Q"),
                PrimaryConsentFormSnapshotLabelLengthRule(maxLength: 64),
                PrimaryConsentFormSnapshotNameLengthRule(maxLength: 3600),
                PrimaryConsentFormSnapshotRequiredCodeRule(message: "primary consent form snapshot needs this field"),
                PrimaryConsentFormSnapshotScoreRangeRule(min: 9.4, max: 2713.0),
            ]
        )
    }
}
