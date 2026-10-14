import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal program segment must pass. Check returns its problems, or none.
    protocol SeasonalProgramSegmentRule {
        func check(_ item: SeasonalProgramSegment) -> [String]
    }

    final class SeasonalProgramSegmentCodePrefixRule: SeasonalProgramSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalProgramSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalProgramSegmentLabelLengthRule: SeasonalProgramSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalProgramSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalProgramSegmentSegmentLengthRule: SeasonalProgramSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalProgramSegment) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalProgramSegmentRequiredContactEmailRule: SeasonalProgramSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalProgramSegment) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalProgramSegmentRequiredCodeRule: SeasonalProgramSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalProgramSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalProgramSegmentRequiredSegmentRule: SeasonalProgramSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalProgramSegment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal program segment.
    final class SeasonalProgramSegmentValidator {
        var rules: [any SeasonalProgramSegmentRule]

        init(rules: [any SeasonalProgramSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalProgramSegment) -> [String] {
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

        func requireValid(_ item: SeasonalProgramSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalProgramSegment]) -> [String: [String]] {
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

    static func defaultSeasonalProgramSegmentValidator() -> SeasonalProgramSegmentValidator {
        return SeasonalProgramSegmentValidator(
            rules: [
                SeasonalProgramSegmentCodePrefixRule(prefix: "ACM"),
                SeasonalProgramSegmentLabelLengthRule(maxLength: 255),
                SeasonalProgramSegmentSegmentLengthRule(maxLength: 16),
                SeasonalProgramSegmentRequiredContactEmailRule(message: "seasonal program segment needs this field"),
                SeasonalProgramSegmentRequiredCodeRule(message: "seasonal program segment needs an entry"),
                SeasonalProgramSegmentRequiredSegmentRule(message: "seasonal program segment needs this field"),
            ]
        )
    }
}
