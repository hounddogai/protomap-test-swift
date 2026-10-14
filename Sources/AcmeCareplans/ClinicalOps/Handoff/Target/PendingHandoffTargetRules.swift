import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending handoff target must pass. Check returns its problems, or none.
    protocol PendingHandoffTargetRule {
        func check(_ item: PendingHandoffTarget) -> [String]
    }

    final class PendingHandoffTargetTimezoneLengthRule: PendingHandoffTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingHandoffTarget) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingHandoffTargetRevisionRangeRule: PendingHandoffTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffTarget) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingHandoffTargetLabelLengthRule: PendingHandoffTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingHandoffTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingHandoffTargetAllowedTimezoneRule: PendingHandoffTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingHandoffTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a pending handoff target.
    final class PendingHandoffTargetValidator {
        var rules: [any PendingHandoffTargetRule]

        init(rules: [any PendingHandoffTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingHandoffTarget) -> [String] {
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

        func requireValid(_ item: PendingHandoffTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingHandoffTarget]) -> [String: [String]] {
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

    static func defaultPendingHandoffTargetValidator() -> PendingHandoffTargetValidator {
        return PendingHandoffTargetValidator(
            rules: [
                PendingHandoffTargetTimezoneLengthRule(maxLength: 3600),
                PendingHandoffTargetRevisionRangeRule(min: 32, max: 3600),
                PendingHandoffTargetLabelLengthRule(maxLength: 3600),
                PendingHandoffTargetAllowedTimezoneRule(allowed: ["legacy"]),
            ]
        )
    }
}
