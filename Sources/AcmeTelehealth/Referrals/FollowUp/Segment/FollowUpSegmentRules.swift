import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up segment must pass. Check returns its problems, or none.
    protocol FollowUpSegmentRule {
        func check(_ item: FollowUpSegment) -> [String]
    }

    final class FollowUpSegmentCodePrefixRule: FollowUpSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpSegmentAllowedChannelRule: FollowUpSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is not allowed"]
            }
            return []
        }
    }

    final class FollowUpSegmentFacilityLengthRule: FollowUpSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpSegment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up segment.
    final class FollowUpSegmentValidator {
        var rules: [any FollowUpSegmentRule]

        init(rules: [any FollowUpSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpSegment) -> [String] {
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

        func requireValid(_ item: FollowUpSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpSegment]) -> [String: [String]] {
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

    static func defaultFollowUpSegmentValidator() -> FollowUpSegmentValidator {
        return FollowUpSegmentValidator(
            rules: [
                FollowUpSegmentCodePrefixRule(prefix: "ACM"),
                FollowUpSegmentAllowedChannelRule(allowed: ["fallback", "rolling", "lenient"]),
                FollowUpSegmentFacilityLengthRule(maxLength: 3600),
            ]
        )
    }
}
