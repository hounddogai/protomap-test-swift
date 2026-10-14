import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending care gap target must pass. Check returns its problems, or none.
    protocol PendingCareGapTargetRule {
        func check(_ item: PendingCareGapTarget) -> [String]
    }

    final class PendingCareGapTargetRequiredTitleRule: PendingCareGapTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareGapTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareGapTargetTitleLengthRule: PendingCareGapTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareGapTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareGapTargetBatchSizeRangeRule: PendingCareGapTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCareGapTarget) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCareGapTargetAllowedLabelRule: PendingCareGapTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCareGapTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class PendingCareGapTargetCodePrefixRule: PendingCareGapTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCareGapTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingCareGapTargetMaximumRangeRule: PendingCareGapTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCareGapTarget) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending care gap target.
    final class PendingCareGapTargetValidator {
        var rules: [any PendingCareGapTargetRule]

        init(rules: [any PendingCareGapTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCareGapTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCareGapTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCareGapTarget]) -> [String: [String]] {
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

    static func defaultPendingCareGapTargetValidator() -> PendingCareGapTargetValidator {
        return PendingCareGapTargetValidator(
            rules: [
                PendingCareGapTargetRequiredTitleRule(message: "pending care gap target needs a value"),
                PendingCareGapTargetTitleLengthRule(maxLength: 64),
                PendingCareGapTargetBatchSizeRangeRule(min: 64, max: 1000),
                PendingCareGapTargetAllowedLabelRule(allowed: ["regional", "global"]),
                PendingCareGapTargetCodePrefixRule(prefix: "X"),
                PendingCareGapTargetMaximumRangeRule(min: 0.7, max: 2012.4),
            ]
        )
    }
}
