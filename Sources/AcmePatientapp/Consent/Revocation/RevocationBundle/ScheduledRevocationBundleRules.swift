import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled revocation bundle must pass. Check returns its problems, or none.
    protocol ScheduledRevocationBundleRule {
        func check(_ item: ScheduledRevocationBundle) -> [String]
    }

    final class ScheduledRevocationBundleSequenceRangeRule: ScheduledRevocationBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRevocationBundle) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledRevocationBundleDosageMgRangeRule: ScheduledRevocationBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRevocationBundle) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledRevocationBundleTitleLengthRule: ScheduledRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRevocationBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRevocationBundleCodeLengthRule: ScheduledRevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRevocationBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRevocationBundleAllowedRegionRule: ScheduledRevocationBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledRevocationBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is missing"]
            }
            return []
        }
    }

    final class ScheduledRevocationBundleRequiredDescriptionRule: ScheduledRevocationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRevocationBundle) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled revocation bundle.
    final class ScheduledRevocationBundleValidator {
        var rules: [any ScheduledRevocationBundleRule]

        init(rules: [any ScheduledRevocationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRevocationBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledRevocationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRevocationBundle]) -> [String: [String]] {
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

    static func defaultScheduledRevocationBundleValidator() -> ScheduledRevocationBundleValidator {
        return ScheduledRevocationBundleValidator(
            rules: [
                ScheduledRevocationBundleSequenceRangeRule(min: 16, max: 1000),
                ScheduledRevocationBundleDosageMgRangeRule(min: 6.2, max: 4351.2),
                ScheduledRevocationBundleTitleLengthRule(maxLength: 32),
                ScheduledRevocationBundleCodeLengthRule(maxLength: 86400),
                ScheduledRevocationBundleAllowedRegionRule(allowed: ["pending", "capped"]),
                ScheduledRevocationBundleRequiredDescriptionRule(
                    message: "scheduled revocation bundle needs this field"
                ),
            ]
        )
    }
}
