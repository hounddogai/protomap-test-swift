import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program segment must pass. Check returns its problems, or none.
    protocol ProgramSegmentRule {
        func check(_ item: ProgramSegment) -> [String]
    }

    final class ProgramSegmentBedLengthRule: ProgramSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramSegment) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramSegmentTimezoneLengthRule: ProgramSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramSegment) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramSegmentCodePrefixRule: ProgramSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramSegmentRequiredBedRule: ProgramSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramSegment) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramSegmentAllowedCodeRule: ProgramSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a program segment.
    final class ProgramSegmentValidator {
        var rules: [any ProgramSegmentRule]

        init(rules: [any ProgramSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramSegment]) -> [String: [String]] {
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

    static func defaultProgramSegmentValidator() -> ProgramSegmentValidator {
        return ProgramSegmentValidator(
            rules: [
                ProgramSegmentBedLengthRule(maxLength: 1000),
                ProgramSegmentTimezoneLengthRule(maxLength: 80),
                ProgramSegmentCodePrefixRule(prefix: "Q"),
                ProgramSegmentRequiredBedRule(message: "program segment needs an entry"),
                ProgramSegmentAllowedCodeRule(allowed: []),
            ]
        )
    }
}
