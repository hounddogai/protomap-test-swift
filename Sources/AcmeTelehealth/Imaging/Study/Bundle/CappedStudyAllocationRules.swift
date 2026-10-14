import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped study allocation must pass. Check returns its problems, or none.
    protocol CappedStudyAllocationRule {
        func check(_ item: CappedStudyAllocation) -> [String]
    }

    final class CappedStudyAllocationRequiredContactEmailRule: CappedStudyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedStudyAllocation) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedStudyAllocationRequiredCountryRule: CappedStudyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedStudyAllocation) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedStudyAllocationCodePrefixRule: CappedStudyAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedStudyAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped study allocation.
    final class CappedStudyAllocationValidator {
        var rules: [any CappedStudyAllocationRule]

        init(rules: [any CappedStudyAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedStudyAllocation) -> [String] {
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

        func requireValid(_ item: CappedStudyAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedStudyAllocation]) -> [String: [String]] {
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

    static func defaultCappedStudyAllocationValidator() -> CappedStudyAllocationValidator {
        return CappedStudyAllocationValidator(
            rules: [
                CappedStudyAllocationRequiredContactEmailRule(message: "capped study allocation needs this field"),
                CappedStudyAllocationRequiredCountryRule(message: "capped study allocation needs a value"),
                CappedStudyAllocationCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
