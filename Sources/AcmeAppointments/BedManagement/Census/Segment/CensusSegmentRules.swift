import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census segment must pass. Check returns its problems, or none.
    protocol CensusSegmentRule {
        func check(_ item: CensusSegment) -> [String]
    }

    final class CensusSegmentCodeLengthRule: CensusSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusSegmentCodePrefixRule: CensusSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusSegmentRequiredNotesRule: CensusSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusSegment) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusSegmentLabelLengthRule: CensusSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusSegmentNotesLengthRule: CensusSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusSegment) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census segment.
    final class CensusSegmentValidator {
        var rules: [any CensusSegmentRule]

        init(rules: [any CensusSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusSegment]) -> [String: [String]] {
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

    static func defaultCensusSegmentValidator() -> CensusSegmentValidator {
        return CensusSegmentValidator(
            rules: [
                CensusSegmentCodeLengthRule(maxLength: 16),
                CensusSegmentCodePrefixRule(prefix: "Q"),
                CensusSegmentRequiredNotesRule(message: "census segment needs a value"),
                CensusSegmentLabelLengthRule(maxLength: 80),
                CensusSegmentNotesLengthRule(maxLength: 80),
            ]
        )
    }
}
