import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive outreach segment must pass. Check returns its problems, or none.
    protocol AdaptiveOutreachSegmentRule {
        func check(_ item: AdaptiveOutreachSegment) -> [String]
    }

    final class AdaptiveOutreachSegmentNameLengthRule: AdaptiveOutreachSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOutreachSegment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachSegmentAllowedCodeRule: AdaptiveOutreachSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveOutreachSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class AdaptiveOutreachSegmentRequiredCodeRule: AdaptiveOutreachSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOutreachSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive outreach segment.
    final class AdaptiveOutreachSegmentValidator {
        var rules: [any AdaptiveOutreachSegmentRule]

        init(rules: [any AdaptiveOutreachSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOutreachSegment) -> [String] {
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

        func requireValid(_ item: AdaptiveOutreachSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOutreachSegment]) -> [String: [String]] {
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

    static func defaultAdaptiveOutreachSegmentValidator() -> AdaptiveOutreachSegmentValidator {
        return AdaptiveOutreachSegmentValidator(
            rules: [
                AdaptiveOutreachSegmentNameLengthRule(maxLength: 32),
                AdaptiveOutreachSegmentAllowedCodeRule(allowed: ["lenient", "legacy"]),
                AdaptiveOutreachSegmentRequiredCodeRule(message: "adaptive outreach segment needs this field"),
            ]
        )
    }
}
