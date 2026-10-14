import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program notice must pass. Check returns its problems, or none.
    protocol ProgramNoticeRule {
        func check(_ item: ProgramNotice) -> [String]
    }

    final class ProgramNoticeRateRangeRule: ProgramNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramNotice) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramNoticeTitleLengthRule: ProgramNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramNoticeAllowedTitleRule: ProgramNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    final class ProgramNoticeRequiredCodeRule: ProgramNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramNoticeCodePrefixRule: ProgramNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramNoticeCodeLengthRule: ProgramNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a program notice.
    final class ProgramNoticeValidator {
        var rules: [any ProgramNoticeRule]

        init(rules: [any ProgramNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramNotice) -> [String] {
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

        func requireValid(_ item: ProgramNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramNotice]) -> [String: [String]] {
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

    static func defaultProgramNoticeValidator() -> ProgramNoticeValidator {
        return ProgramNoticeValidator(
            rules: [
                ProgramNoticeRateRangeRule(min: 4.3, max: 1661.2),
                ProgramNoticeTitleLengthRule(maxLength: 16),
                ProgramNoticeAllowedTitleRule(allowed: []),
                ProgramNoticeRequiredCodeRule(message: "program notice needs a value"),
                ProgramNoticeCodePrefixRule(prefix: "REF"),
                ProgramNoticeCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
