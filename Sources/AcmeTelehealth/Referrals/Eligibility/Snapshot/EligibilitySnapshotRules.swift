import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility snapshot must pass. Check returns its problems, or none.
    protocol EligibilitySnapshotRule {
        func check(_ item: EligibilitySnapshot) -> [String]
    }

    final class EligibilitySnapshotRequiredLabelRule: EligibilitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilitySnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilitySnapshotRequiredNameRule: EligibilitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilitySnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilitySnapshotCodeLengthRule: EligibilitySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilitySnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilitySnapshotLabelLengthRule: EligibilitySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilitySnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilitySnapshotNameLengthRule: EligibilitySnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilitySnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilitySnapshotRequiredCodeRule: EligibilitySnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilitySnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility snapshot.
    final class EligibilitySnapshotValidator {
        var rules: [any EligibilitySnapshotRule]

        init(rules: [any EligibilitySnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilitySnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilitySnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilitySnapshot]) -> [String: [String]] {
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

    static func defaultEligibilitySnapshotValidator() -> EligibilitySnapshotValidator {
        return EligibilitySnapshotValidator(
            rules: [
                EligibilitySnapshotRequiredLabelRule(message: "eligibility snapshot needs this field"),
                EligibilitySnapshotRequiredNameRule(message: "eligibility snapshot needs a value"),
                EligibilitySnapshotCodeLengthRule(maxLength: 120),
                EligibilitySnapshotLabelLengthRule(maxLength: 64),
                EligibilitySnapshotNameLengthRule(maxLength: 80),
                EligibilitySnapshotRequiredCodeRule(message: "eligibility snapshot needs a value"),
            ]
        )
    }
}
