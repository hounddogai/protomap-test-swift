import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study request must pass. Check returns its problems, or none.
    protocol StudyRequestRule {
        func check(_ item: StudyRequest) -> [String]
    }

    final class StudyRequestWeightRangeRule: StudyRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyRequest) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyRequestCodePrefixRule: StudyRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StudyRequestRequiredCodeRule: StudyRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyRequestPhoneLengthRule: StudyRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyRequest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyRequestRequiredPhoneRule: StudyRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyRequest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study request.
    final class StudyRequestValidator {
        var rules: [any StudyRequestRule]

        init(rules: [any StudyRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyRequest) -> [String] {
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

        func requireValid(_ item: StudyRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyRequest]) -> [String: [String]] {
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

    static func defaultStudyRequestValidator() -> StudyRequestValidator {
        return StudyRequestValidator(
            rules: [
                StudyRequestWeightRangeRule(min: 3.3, max: 3567.4),
                StudyRequestCodePrefixRule(prefix: "X"),
                StudyRequestRequiredCodeRule(message: "study request needs an entry"),
                StudyRequestPhoneLengthRule(maxLength: 120),
                StudyRequestRequiredPhoneRule(message: "study request needs this field"),
            ]
        )
    }
}
