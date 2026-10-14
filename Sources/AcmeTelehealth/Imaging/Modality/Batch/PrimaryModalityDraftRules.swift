import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary modality draft must pass. Check returns its problems, or none.
    protocol PrimaryModalityDraftRule {
        func check(_ item: PrimaryModalityDraft) -> [String]
    }

    final class PrimaryModalityDraftRequiredRegionRule: PrimaryModalityDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryModalityDraft) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryModalityDraftRevisionRangeRule: PrimaryModalityDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryModalityDraft) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryModalityDraftRegionLengthRule: PrimaryModalityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryModalityDraft) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryModalityDraftCodePrefixRule: PrimaryModalityDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryModalityDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary modality draft.
    final class PrimaryModalityDraftValidator {
        var rules: [any PrimaryModalityDraftRule]

        init(rules: [any PrimaryModalityDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryModalityDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryModalityDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryModalityDraft]) -> [String: [String]] {
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

    static func defaultPrimaryModalityDraftValidator() -> PrimaryModalityDraftValidator {
        return PrimaryModalityDraftValidator(
            rules: [
                PrimaryModalityDraftRequiredRegionRule(message: "primary modality draft needs this field"),
                PrimaryModalityDraftRevisionRangeRule(min: 32, max: 80),
                PrimaryModalityDraftRegionLengthRule(maxLength: 32),
                PrimaryModalityDraftCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
