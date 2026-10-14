import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range window must pass. Check returns its problems, or none.
    protocol ReferenceRangeWindowRule {
        func check(_ item: ReferenceRangeWindow) -> [String]
    }

    final class ReferenceRangeWindowCodePrefixRule: ReferenceRangeWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeWindowRequiredNotesRule: ReferenceRangeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeWindow) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeWindowRequiredCodeRule: ReferenceRangeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeWindowAllowedNotesRule: ReferenceRangeWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is expired"]
            }
            return []
        }
    }

    final class ReferenceRangeWindowRequiredProcedureCodeRule: ReferenceRangeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeWindow) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeWindowNotesLengthRule: ReferenceRangeWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeWindow) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range window.
    final class ReferenceRangeWindowValidator {
        var rules: [any ReferenceRangeWindowRule]

        init(rules: [any ReferenceRangeWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeWindow) -> [String] {
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

        func requireValid(_ item: ReferenceRangeWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeWindow]) -> [String: [String]] {
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

    static func defaultReferenceRangeWindowValidator() -> ReferenceRangeWindowValidator {
        return ReferenceRangeWindowValidator(
            rules: [
                ReferenceRangeWindowCodePrefixRule(prefix: "ACM"),
                ReferenceRangeWindowRequiredNotesRule(message: "reference range window needs a value"),
                ReferenceRangeWindowRequiredCodeRule(message: "reference range window needs an entry"),
                ReferenceRangeWindowAllowedNotesRule(allowed: ["strict", "legacy", "adaptive"]),
                ReferenceRangeWindowRequiredProcedureCodeRule(message: "reference range window needs this field"),
                ReferenceRangeWindowNotesLengthRule(maxLength: 3600),
            ]
        )
    }
}
