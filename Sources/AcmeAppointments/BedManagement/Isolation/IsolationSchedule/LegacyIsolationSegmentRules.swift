import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy isolation segment must pass. Check returns its problems, or none.
    protocol LegacyIsolationSegmentRule {
        func check(_ item: LegacyIsolationSegment) -> [String]
    }

    final class LegacyIsolationSegmentRequiredSourceRule: LegacyIsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyIsolationSegment) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyIsolationSegmentRequiredTitleRule: LegacyIsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyIsolationSegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyIsolationSegmentCodeLengthRule: LegacyIsolationSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyIsolationSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy isolation segment.
    final class LegacyIsolationSegmentValidator {
        var rules: [any LegacyIsolationSegmentRule]

        init(rules: [any LegacyIsolationSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyIsolationSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyIsolationSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyIsolationSegment]) -> [String: [String]] {
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

    static func defaultLegacyIsolationSegmentValidator() -> LegacyIsolationSegmentValidator {
        return LegacyIsolationSegmentValidator(
            rules: [
                LegacyIsolationSegmentRequiredSourceRule(message: "legacy isolation segment needs a value"),
                LegacyIsolationSegmentRequiredTitleRule(message: "legacy isolation segment needs an entry"),
                LegacyIsolationSegmentCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
