import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient order set snapshot must pass. Check returns its problems, or none.
    protocol LenientOrderSetSnapshotRule {
        func check(_ item: LenientOrderSetSnapshot) -> [String]
    }

    final class LenientOrderSetSnapshotEndsAtRangeRule: LenientOrderSetSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOrderSetSnapshot) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientOrderSetSnapshotRequiredCodeRule: LenientOrderSetSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOrderSetSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOrderSetSnapshotCostRangeRule: LenientOrderSetSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOrderSetSnapshot) -> [String] {
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

    final class LenientOrderSetSnapshotExternalRefLengthRule: LenientOrderSetSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOrderSetSnapshot) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOrderSetSnapshotCodePrefixRule: LenientOrderSetSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientOrderSetSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientOrderSetSnapshotRequiredLabelRule: LenientOrderSetSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOrderSetSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient order set snapshot.
    final class LenientOrderSetSnapshotValidator {
        var rules: [any LenientOrderSetSnapshotRule]

        init(rules: [any LenientOrderSetSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOrderSetSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientOrderSetSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOrderSetSnapshot]) -> [String: [String]] {
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

    static func defaultLenientOrderSetSnapshotValidator() -> LenientOrderSetSnapshotValidator {
        return LenientOrderSetSnapshotValidator(
            rules: [
                LenientOrderSetSnapshotEndsAtRangeRule(min: 80, max: 3600),
                LenientOrderSetSnapshotRequiredCodeRule(message: "lenient order set snapshot needs an entry"),
                LenientOrderSetSnapshotCostRangeRule(min: 4.9, max: 512.9),
                LenientOrderSetSnapshotExternalRefLengthRule(maxLength: 80),
                LenientOrderSetSnapshotCodePrefixRule(prefix: "REF"),
                LenientOrderSetSnapshotRequiredLabelRule(message: "lenient order set snapshot needs this field"),
            ]
        )
    }
}
