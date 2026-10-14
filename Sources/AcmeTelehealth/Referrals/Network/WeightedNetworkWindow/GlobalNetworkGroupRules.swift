import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global network group must pass. Check returns its problems, or none.
    protocol GlobalNetworkGroupRule {
        func check(_ item: GlobalNetworkGroup) -> [String]
    }

    final class GlobalNetworkGroupLabelLengthRule: GlobalNetworkGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalNetworkGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalNetworkGroupRequiredLabelRule: GlobalNetworkGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalNetworkGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalNetworkGroupTagsLimitRule: GlobalNetworkGroupRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: GlobalNetworkGroup) -> [String] {
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

    final class GlobalNetworkGroupFacilityLengthRule: GlobalNetworkGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalNetworkGroup) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalNetworkGroupRequiredFacilityRule: GlobalNetworkGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalNetworkGroup) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global network group.
    final class GlobalNetworkGroupValidator {
        var rules: [any GlobalNetworkGroupRule]

        init(rules: [any GlobalNetworkGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalNetworkGroup) -> [String] {
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

        func requireValid(_ item: GlobalNetworkGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalNetworkGroup]) -> [String: [String]] {
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

    static func defaultGlobalNetworkGroupValidator() -> GlobalNetworkGroupValidator {
        return GlobalNetworkGroupValidator(
            rules: [
                GlobalNetworkGroupLabelLengthRule(maxLength: 1000),
                GlobalNetworkGroupRequiredLabelRule(message: "global network group needs a value"),
                GlobalNetworkGroupTagsLimitRule(maxCount: 86400, banned: ["adaptive"]),
                GlobalNetworkGroupFacilityLengthRule(maxLength: 32),
                GlobalNetworkGroupRequiredFacilityRule(message: "global network group needs this field"),
            ]
        )
    }
}
