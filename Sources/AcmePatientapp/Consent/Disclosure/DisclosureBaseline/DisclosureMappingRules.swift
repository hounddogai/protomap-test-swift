import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure mapping must pass. Check returns its problems, or none.
    protocol DisclosureMappingRule {
        func check(_ item: DisclosureMapping) -> [String]
    }

    final class DisclosureMappingCodePrefixRule: DisclosureMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureMappingRequiredSegmentRule: DisclosureMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureMapping) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureMappingRequiredSourceRule: DisclosureMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureMapping) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureMappingSourceLengthRule: DisclosureMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureMapping) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureMappingTitleLengthRule: DisclosureMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureMappingSegmentLengthRule: DisclosureMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureMapping) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure mapping.
    final class DisclosureMappingValidator {
        var rules: [any DisclosureMappingRule]

        init(rules: [any DisclosureMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureMapping]) -> [String: [String]] {
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

    static func defaultDisclosureMappingValidator() -> DisclosureMappingValidator {
        return DisclosureMappingValidator(
            rules: [
                DisclosureMappingCodePrefixRule(prefix: "REF"),
                DisclosureMappingRequiredSegmentRule(message: "disclosure mapping needs a value"),
                DisclosureMappingRequiredSourceRule(message: "disclosure mapping needs a value"),
                DisclosureMappingSourceLengthRule(maxLength: 32),
                DisclosureMappingTitleLengthRule(maxLength: 80),
                DisclosureMappingSegmentLengthRule(maxLength: 16),
            ]
        )
    }
}
