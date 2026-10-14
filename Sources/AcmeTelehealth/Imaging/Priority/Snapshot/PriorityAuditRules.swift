import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority audit must pass. Check returns its problems, or none.
    protocol PriorityAuditRule {
        func check(_ item: PriorityAudit) -> [String]
    }

    final class PriorityAuditTagsLimitRule: PriorityAuditRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: PriorityAudit) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class PriorityAuditAllowedFacilityRule: PriorityAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PriorityAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is blocked"]
            }
            return []
        }
    }

    final class PriorityAuditCodeLengthRule: PriorityAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityAuditCodePrefixRule: PriorityAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PriorityAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PriorityAuditRequiredFacilityRule: PriorityAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityAudit) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityAuditVisitMinutesRangeRule: PriorityAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityAudit) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority audit.
    final class PriorityAuditValidator {
        var rules: [any PriorityAuditRule]

        init(rules: [any PriorityAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityAudit) -> [String] {
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

        func requireValid(_ item: PriorityAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityAudit]) -> [String: [String]] {
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

    static func defaultPriorityAuditValidator() -> PriorityAuditValidator {
        return PriorityAuditValidator(
            rules: [
                PriorityAuditTagsLimitRule(maxCount: 3600, banned: ["regional"]),
                PriorityAuditAllowedFacilityRule(allowed: ["global", "adaptive", "adaptive"]),
                PriorityAuditCodeLengthRule(maxLength: 80),
                PriorityAuditCodePrefixRule(prefix: "Q"),
                PriorityAuditRequiredFacilityRule(message: "priority audit needs this field"),
                PriorityAuditVisitMinutesRangeRule(min: 32, max: 80),
            ]
        )
    }
}
