import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense snapshot must pass. Check returns its problems, or none.
    protocol DispenseSnapshotRule {
        func check(_ item: DispenseSnapshot) -> [String]
    }

    final class DispenseSnapshotCodePrefixRule: DispenseSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseSnapshotRequiredCodeRule: DispenseSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseSnapshotDosageMgRangeRule: DispenseSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseSnapshot) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense snapshot.
    final class DispenseSnapshotValidator {
        var rules: [any DispenseSnapshotRule]

        init(rules: [any DispenseSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseSnapshot) -> [String] {
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

        func requireValid(_ item: DispenseSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseSnapshot]) -> [String: [String]] {
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

    static func defaultDispenseSnapshotValidator() -> DispenseSnapshotValidator {
        return DispenseSnapshotValidator(
            rules: [
                DispenseSnapshotCodePrefixRule(prefix: "Q"),
                DispenseSnapshotRequiredCodeRule(message: "dispense snapshot needs an entry"),
                DispenseSnapshotDosageMgRangeRule(min: 1.3, max: 1385.3),
            ]
        )
    }
}
