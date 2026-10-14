import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual study segment must pass. Check returns its problems, or none.
    protocol ManualStudySegmentRule {
        func check(_ item: ManualStudySegment) -> [String]
    }

    final class ManualStudySegmentCodePrefixRule: ManualStudySegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualStudySegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualStudySegmentBedLengthRule: ManualStudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualStudySegment) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualStudySegmentCodeLengthRule: ManualStudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualStudySegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualStudySegmentAllowedCodeRule: ManualStudySegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualStudySegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class ManualStudySegmentRequiredBedRule: ManualStudySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualStudySegment) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual study segment.
    final class ManualStudySegmentValidator {
        var rules: [any ManualStudySegmentRule]

        init(rules: [any ManualStudySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualStudySegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualStudySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualStudySegment]) -> [String: [String]] {
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

    static func defaultManualStudySegmentValidator() -> ManualStudySegmentValidator {
        return ManualStudySegmentValidator(
            rules: [
                ManualStudySegmentCodePrefixRule(prefix: "Q"),
                ManualStudySegmentBedLengthRule(maxLength: 16),
                ManualStudySegmentCodeLengthRule(maxLength: 64),
                ManualStudySegmentAllowedCodeRule(allowed: []),
                ManualStudySegmentRequiredBedRule(message: "manual study segment needs a value"),
            ]
        )
    }
}
