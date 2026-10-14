import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback closure snapshot must pass. Check returns its problems, or none.
    protocol FallbackClosureSnapshotRule {
        func check(_ item: FallbackClosureSnapshot) -> [String]
    }

    final class FallbackClosureSnapshotRequiredChannelRule: FallbackClosureSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClosureSnapshot) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackClosureSnapshotDiscountRangeRule: FallbackClosureSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackClosureSnapshot) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackClosureSnapshotWardLengthRule: FallbackClosureSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackClosureSnapshot) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackClosureSnapshotCodePrefixRule: FallbackClosureSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackClosureSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback closure snapshot.
    final class FallbackClosureSnapshotValidator {
        var rules: [any FallbackClosureSnapshotRule]

        init(rules: [any FallbackClosureSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackClosureSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackClosureSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackClosureSnapshot]) -> [String: [String]] {
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

    static func defaultFallbackClosureSnapshotValidator() -> FallbackClosureSnapshotValidator {
        return FallbackClosureSnapshotValidator(
            rules: [
                FallbackClosureSnapshotRequiredChannelRule(message: "fallback closure snapshot needs this field"),
                FallbackClosureSnapshotDiscountRangeRule(min: 1.2, max: 4551.2),
                FallbackClosureSnapshotWardLengthRule(maxLength: 255),
                FallbackClosureSnapshotCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
