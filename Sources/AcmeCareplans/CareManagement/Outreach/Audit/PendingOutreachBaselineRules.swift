import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending outreach baseline must pass. Check returns its problems, or none.
    protocol PendingOutreachBaselineRule {
        func check(_ item: PendingOutreachBaseline) -> [String]
    }

    final class PendingOutreachBaselineSequenceRangeRule: PendingOutreachBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOutreachBaseline) -> [String] {
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

    final class PendingOutreachBaselineCodeLengthRule: PendingOutreachBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOutreachBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOutreachBaselineOwnerIDLengthRule: PendingOutreachBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOutreachBaseline) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOutreachBaselineLabelLengthRule: PendingOutreachBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOutreachBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOutreachBaselineAllowedOwnerIDRule: PendingOutreachBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingOutreachBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is inconsistent"]
            }
            return []
        }
    }

    final class PendingOutreachBaselineRequiredCodeRule: PendingOutreachBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOutreachBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending outreach baseline.
    final class PendingOutreachBaselineValidator {
        var rules: [any PendingOutreachBaselineRule]

        init(rules: [any PendingOutreachBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOutreachBaseline) -> [String] {
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

        func requireValid(_ item: PendingOutreachBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOutreachBaseline]) -> [String: [String]] {
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

    static func defaultPendingOutreachBaselineValidator() -> PendingOutreachBaselineValidator {
        return PendingOutreachBaselineValidator(
            rules: [
                PendingOutreachBaselineSequenceRangeRule(min: 120, max: 1000),
                PendingOutreachBaselineCodeLengthRule(maxLength: 64),
                PendingOutreachBaselineOwnerIDLengthRule(maxLength: 86400),
                PendingOutreachBaselineLabelLengthRule(maxLength: 3600),
                PendingOutreachBaselineAllowedOwnerIDRule(allowed: ["weighted", "adaptive", "scheduled"]),
                PendingOutreachBaselineRequiredCodeRule(message: "pending outreach baseline needs this field"),
            ]
        )
    }
}
