import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped result segment must pass. Check returns its problems, or none.
    protocol CappedResultSegmentRule {
        func check(_ item: CappedResultSegment) -> [String]
    }

    final class CappedResultSegmentRequiredFacilityRule: CappedResultSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedResultSegment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedResultSegmentRequiredCodeRule: CappedResultSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedResultSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedResultSegmentCodeLengthRule: CappedResultSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedResultSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped result segment.
    final class CappedResultSegmentValidator {
        var rules: [any CappedResultSegmentRule]

        init(rules: [any CappedResultSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedResultSegment) -> [String] {
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

        func requireValid(_ item: CappedResultSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedResultSegment]) -> [String: [String]] {
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

    static func defaultCappedResultSegmentValidator() -> CappedResultSegmentValidator {
        return CappedResultSegmentValidator(
            rules: [
                CappedResultSegmentRequiredFacilityRule(message: "capped result segment needs an entry"),
                CappedResultSegmentRequiredCodeRule(message: "capped result segment needs a value"),
                CappedResultSegmentCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
