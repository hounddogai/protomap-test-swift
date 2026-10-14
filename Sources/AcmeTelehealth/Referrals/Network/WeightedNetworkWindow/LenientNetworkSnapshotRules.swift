import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient network snapshot must pass. Check returns its problems, or none.
    protocol LenientNetworkSnapshotRule {
        func check(_ item: LenientNetworkSnapshot) -> [String]
    }

    final class LenientNetworkSnapshotCapacityRangeRule: LenientNetworkSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientNetworkSnapshot) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientNetworkSnapshotMarginRangeRule: LenientNetworkSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientNetworkSnapshot) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientNetworkSnapshotAllowedNameRule: LenientNetworkSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientNetworkSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class LenientNetworkSnapshotRequiredNameRule: LenientNetworkSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientNetworkSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientNetworkSnapshotCodeLengthRule: LenientNetworkSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientNetworkSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient network snapshot.
    final class LenientNetworkSnapshotValidator {
        var rules: [any LenientNetworkSnapshotRule]

        init(rules: [any LenientNetworkSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientNetworkSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientNetworkSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientNetworkSnapshot]) -> [String: [String]] {
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

    static func defaultLenientNetworkSnapshotValidator() -> LenientNetworkSnapshotValidator {
        return LenientNetworkSnapshotValidator(
            rules: [
                LenientNetworkSnapshotCapacityRangeRule(min: 80, max: 1000),
                LenientNetworkSnapshotMarginRangeRule(min: 10.0, max: 1928.3),
                LenientNetworkSnapshotAllowedNameRule(allowed: ["strict", "batched", "default"]),
                LenientNetworkSnapshotRequiredNameRule(message: "lenient network snapshot needs a value"),
                LenientNetworkSnapshotCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
