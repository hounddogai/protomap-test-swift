import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation segment must pass. Check returns its problems, or none.
    protocol IsolationSegmentRule {
        func check(_ item: IsolationSegment) -> [String]
    }

    final class IsolationSegmentRequiredCountryRule: IsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationSegment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationSegmentRequiredTitleRule: IsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationSegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationSegmentTitleLengthRule: IsolationSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationSegmentRequiredCodeRule: IsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationSegmentCountryLengthRule: IsolationSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationSegment) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation segment.
    final class IsolationSegmentValidator {
        var rules: [any IsolationSegmentRule]

        init(rules: [any IsolationSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationSegment]) -> [String: [String]] {
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

    static func defaultIsolationSegmentValidator() -> IsolationSegmentValidator {
        return IsolationSegmentValidator(
            rules: [
                IsolationSegmentRequiredCountryRule(message: "isolation segment needs this field"),
                IsolationSegmentRequiredTitleRule(message: "isolation segment needs this field"),
                IsolationSegmentTitleLengthRule(maxLength: 16),
                IsolationSegmentRequiredCodeRule(message: "isolation segment needs this field"),
                IsolationSegmentCountryLengthRule(maxLength: 3600),
            ]
        )
    }
}
