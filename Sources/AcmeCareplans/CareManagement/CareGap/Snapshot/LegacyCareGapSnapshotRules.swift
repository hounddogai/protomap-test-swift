import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy care gap snapshot must pass. Check returns its problems, or none.
    protocol LegacyCareGapSnapshotRule {
        func check(_ item: LegacyCareGapSnapshot) -> [String]
    }

    final class LegacyCareGapSnapshotLabelLengthRule: LegacyCareGapSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareGapSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCareGapSnapshotFloorValueRangeRule: LegacyCareGapSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCareGapSnapshot) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCareGapSnapshotCodeLengthRule: LegacyCareGapSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareGapSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCareGapSnapshotRequiredChannelRule: LegacyCareGapSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareGapSnapshot) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCareGapSnapshotAllowedChannelRule: LegacyCareGapSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyCareGapSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is stale"]
            }
            return []
        }
    }

    final class LegacyCareGapSnapshotCodePrefixRule: LegacyCareGapSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyCareGapSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy care gap snapshot.
    final class LegacyCareGapSnapshotValidator {
        var rules: [any LegacyCareGapSnapshotRule]

        init(rules: [any LegacyCareGapSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCareGapSnapshot) -> [String] {
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

        func requireValid(_ item: LegacyCareGapSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCareGapSnapshot]) -> [String: [String]] {
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

    static func defaultLegacyCareGapSnapshotValidator() -> LegacyCareGapSnapshotValidator {
        return LegacyCareGapSnapshotValidator(
            rules: [
                LegacyCareGapSnapshotLabelLengthRule(maxLength: 255),
                LegacyCareGapSnapshotFloorValueRangeRule(min: 8.4, max: 599.0),
                LegacyCareGapSnapshotCodeLengthRule(maxLength: 255),
                LegacyCareGapSnapshotRequiredChannelRule(message: "legacy care gap snapshot needs a value"),
                LegacyCareGapSnapshotAllowedChannelRule(allowed: ["adaptive"]),
                LegacyCareGapSnapshotCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
