import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality draft must pass. Check returns its problems, or none.
    protocol ModalityDraftRule {
        func check(_ item: ModalityDraft) -> [String]
    }

    final class ModalityDraftRequiredExternalRefRule: ModalityDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityDraft) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityDraftAllowedLabelRule: ModalityDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class ModalityDraftLabelLengthRule: ModalityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityDraftAcuityRangeRule: ModalityDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityDraft) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalityDraftCodePrefixRule: ModalityDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityDraftNameLengthRule: ModalityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality draft.
    final class ModalityDraftValidator {
        var rules: [any ModalityDraftRule]

        init(rules: [any ModalityDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityDraft]) -> [String: [String]] {
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

    static func defaultModalityDraftValidator() -> ModalityDraftValidator {
        return ModalityDraftValidator(
            rules: [
                ModalityDraftRequiredExternalRefRule(message: "modality draft needs a value"),
                ModalityDraftAllowedLabelRule(allowed: ["adaptive", "tiered"]),
                ModalityDraftLabelLengthRule(maxLength: 32),
                ModalityDraftAcuityRangeRule(min: 64, max: 120),
                ModalityDraftCodePrefixRule(prefix: "OPS"),
                ModalityDraftNameLengthRule(maxLength: 16),
            ]
        )
    }
}
