import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling result segment must pass. Check returns its problems, or none.
    protocol RollingResultSegmentRule {
        func check(_ item: RollingResultSegment) -> [String]
    }

    final class RollingResultSegmentRequiredSummaryRule: RollingResultSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultSegment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingResultSegmentLabelLengthRule: RollingResultSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingResultSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingResultSegmentRequiredLabelRule: RollingResultSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingResultSegmentLocaleLengthRule: RollingResultSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingResultSegment) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingResultSegmentCodePrefixRule: RollingResultSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingResultSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingResultSegmentAllowedSummaryRule: RollingResultSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingResultSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling result segment.
    final class RollingResultSegmentValidator {
        var rules: [any RollingResultSegmentRule]

        init(rules: [any RollingResultSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingResultSegment) -> [String] {
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

        func requireValid(_ item: RollingResultSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingResultSegment]) -> [String: [String]] {
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

    static func defaultRollingResultSegmentValidator() -> RollingResultSegmentValidator {
        return RollingResultSegmentValidator(
            rules: [
                RollingResultSegmentRequiredSummaryRule(message: "rolling result segment needs an entry"),
                RollingResultSegmentLabelLengthRule(maxLength: 3600),
                RollingResultSegmentRequiredLabelRule(message: "rolling result segment needs this field"),
                RollingResultSegmentLocaleLengthRule(maxLength: 16),
                RollingResultSegmentCodePrefixRule(prefix: "ACM"),
                RollingResultSegmentAllowedSummaryRule(allowed: ["default"]),
            ]
        )
    }
}
