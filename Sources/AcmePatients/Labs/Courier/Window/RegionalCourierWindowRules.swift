import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional courier window must pass. Check returns its problems, or none.
    protocol RegionalCourierWindowRule {
        func check(_ item: RegionalCourierWindow) -> [String]
    }

    final class RegionalCourierWindowContactEmailLengthRule: RegionalCourierWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCourierWindow) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCourierWindowDiagnosisCodeLengthRule: RegionalCourierWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCourierWindow) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCourierWindowRequiredContactEmailRule: RegionalCourierWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCourierWindow) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCourierWindowRequiredDiagnosisCodeRule: RegionalCourierWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCourierWindow) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCourierWindowRequiredTitleRule: RegionalCourierWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCourierWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCourierWindowVisibleGuardRule: RegionalCourierWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalCourierWindow) -> [String] {
            if item.visible && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a regional courier window.
    final class RegionalCourierWindowValidator {
        var rules: [any RegionalCourierWindowRule]

        init(rules: [any RegionalCourierWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCourierWindow) -> [String] {
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

        func requireValid(_ item: RegionalCourierWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCourierWindow]) -> [String: [String]] {
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

    static func defaultRegionalCourierWindowValidator() -> RegionalCourierWindowValidator {
        return RegionalCourierWindowValidator(
            rules: [
                RegionalCourierWindowContactEmailLengthRule(maxLength: 255),
                RegionalCourierWindowDiagnosisCodeLengthRule(maxLength: 3600),
                RegionalCourierWindowRequiredContactEmailRule(message: "regional courier window needs an entry"),
                RegionalCourierWindowRequiredDiagnosisCodeRule(message: "regional courier window needs an entry"),
                RegionalCourierWindowRequiredTitleRule(message: "regional courier window needs a value"),
                RegionalCourierWindowVisibleGuardRule(limit: 255),
            ]
        )
    }
}
