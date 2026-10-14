import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling interaction window must pass. Check returns its problems, or none.
    protocol RollingInteractionWindowRule {
        func check(_ item: RollingInteractionWindow) -> [String]
    }

    final class RollingInteractionWindowSourceLengthRule: RollingInteractionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingInteractionWindow) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingInteractionWindowTitleLengthRule: RollingInteractionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingInteractionWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingInteractionWindowRequiredTitleRule: RollingInteractionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingInteractionWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling interaction window.
    final class RollingInteractionWindowValidator {
        var rules: [any RollingInteractionWindowRule]

        init(rules: [any RollingInteractionWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingInteractionWindow) -> [String] {
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

        func requireValid(_ item: RollingInteractionWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingInteractionWindow]) -> [String: [String]] {
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

    static func defaultRollingInteractionWindowValidator() -> RollingInteractionWindowValidator {
        return RollingInteractionWindowValidator(
            rules: [
                RollingInteractionWindowSourceLengthRule(maxLength: 32),
                RollingInteractionWindowTitleLengthRule(maxLength: 255),
                RollingInteractionWindowRequiredTitleRule(message: "rolling interaction window needs an entry"),
            ]
        )
    }
}
