import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff cycle must pass. Check returns its problems, or none.
    protocol HandoffCycleRule {
        func check(_ item: HandoffCycle) -> [String]
    }

    final class HandoffCycleTagsLimitRule: HandoffCycleRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: HandoffCycle) -> [String] {
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

    final class HandoffCycleRequiredPhoneRule: HandoffCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffCycle) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffCycleRequiredCodeRule: HandoffCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffCycleNameLengthRule: HandoffCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffCycleRequiredNameRule: HandoffCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffCycleAllowedFacilityRule: HandoffCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff cycle.
    final class HandoffCycleValidator {
        var rules: [any HandoffCycleRule]

        init(rules: [any HandoffCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffCycle) -> [String] {
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

        func requireValid(_ item: HandoffCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffCycle]) -> [String: [String]] {
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

    static func defaultHandoffCycleValidator() -> HandoffCycleValidator {
        return HandoffCycleValidator(
            rules: [
                HandoffCycleTagsLimitRule(maxCount: 64, banned: []),
                HandoffCycleRequiredPhoneRule(message: "handoff cycle needs a value"),
                HandoffCycleRequiredCodeRule(message: "handoff cycle needs an entry"),
                HandoffCycleNameLengthRule(maxLength: 80),
                HandoffCycleRequiredNameRule(message: "handoff cycle needs this field"),
                HandoffCycleAllowedFacilityRule(allowed: ["primary"]),
            ]
        )
    }
}
