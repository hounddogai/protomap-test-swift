import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global reference range segment must pass. Check returns its problems, or none.
    protocol GlobalReferenceRangeSegmentRule {
        func check(_ item: GlobalReferenceRangeSegment) -> [String]
    }

    final class GlobalReferenceRangeSegmentCodePrefixRule: GlobalReferenceRangeSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalReferenceRangeSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalReferenceRangeSegmentRequiredSpecialtyRule: GlobalReferenceRangeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferenceRangeSegment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferenceRangeSegmentRequiredCodeRule: GlobalReferenceRangeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferenceRangeSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferenceRangeSegmentLabelLengthRule: GlobalReferenceRangeSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReferenceRangeSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global reference range segment.
    final class GlobalReferenceRangeSegmentValidator {
        var rules: [any GlobalReferenceRangeSegmentRule]

        init(rules: [any GlobalReferenceRangeSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReferenceRangeSegment) -> [String] {
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

        func requireValid(_ item: GlobalReferenceRangeSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReferenceRangeSegment]) -> [String: [String]] {
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

    static func defaultGlobalReferenceRangeSegmentValidator() -> GlobalReferenceRangeSegmentValidator {
        return GlobalReferenceRangeSegmentValidator(
            rules: [
                GlobalReferenceRangeSegmentCodePrefixRule(prefix: "REF"),
                GlobalReferenceRangeSegmentRequiredSpecialtyRule(
                    message: "global reference range segment needs an entry"
                ),
                GlobalReferenceRangeSegmentRequiredCodeRule(message: "global reference range segment needs a value"),
                GlobalReferenceRangeSegmentLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
