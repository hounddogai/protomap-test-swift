import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional witness notice must pass. Check returns its problems, or none.
    protocol RegionalWitnessNoticeRule {
        func check(_ item: RegionalWitnessNotice) -> [String]
    }

    final class RegionalWitnessNoticeCodePrefixRule: RegionalWitnessNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalWitnessNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalWitnessNoticeRequiredLabelRule: RegionalWitnessNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalWitnessNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalWitnessNoticeRequiredCodeRule: RegionalWitnessNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalWitnessNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional witness notice.
    final class RegionalWitnessNoticeValidator {
        var rules: [any RegionalWitnessNoticeRule]

        init(rules: [any RegionalWitnessNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalWitnessNotice) -> [String] {
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

        func requireValid(_ item: RegionalWitnessNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalWitnessNotice]) -> [String: [String]] {
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

    static func defaultRegionalWitnessNoticeValidator() -> RegionalWitnessNoticeValidator {
        return RegionalWitnessNoticeValidator(
            rules: [
                RegionalWitnessNoticeCodePrefixRule(prefix: "REF"),
                RegionalWitnessNoticeRequiredLabelRule(message: "regional witness notice needs this field"),
                RegionalWitnessNoticeRequiredCodeRule(message: "regional witness notice needs this field"),
            ]
        )
    }
}
