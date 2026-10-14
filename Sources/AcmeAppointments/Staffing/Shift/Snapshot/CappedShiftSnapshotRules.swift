import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped shift snapshot must pass. Check returns its problems, or none.
    protocol CappedShiftSnapshotRule {
        func check(_ item: CappedShiftSnapshot) -> [String]
    }

    final class CappedShiftSnapshotCodePrefixRule: CappedShiftSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedShiftSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedShiftSnapshotLabelLengthRule: CappedShiftSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedShiftSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedShiftSnapshotRequiredCurrencyRule: CappedShiftSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedShiftSnapshot) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped shift snapshot.
    final class CappedShiftSnapshotValidator {
        var rules: [any CappedShiftSnapshotRule]

        init(rules: [any CappedShiftSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedShiftSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedShiftSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedShiftSnapshot]) -> [String: [String]] {
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

    static func defaultCappedShiftSnapshotValidator() -> CappedShiftSnapshotValidator {
        return CappedShiftSnapshotValidator(
            rules: [
                CappedShiftSnapshotCodePrefixRule(prefix: "ACM"),
                CappedShiftSnapshotLabelLengthRule(maxLength: 255),
                CappedShiftSnapshotRequiredCurrencyRule(message: "capped shift snapshot needs a value"),
            ]
        )
    }
}
