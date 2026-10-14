import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality variance must pass. Check returns its problems, or none.
    protocol ModalityVarianceRule {
        func check(_ item: ModalityVariance) -> [String]
    }

    final class ModalityVarianceCodeLengthRule: ModalityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityVarianceCodePrefixRule: ModalityVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityVarianceRequiredLabelRule: ModalityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityVarianceRefillsRangeRule: ModalityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityVariance) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality variance.
    final class ModalityVarianceValidator {
        var rules: [any ModalityVarianceRule]

        init(rules: [any ModalityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityVariance) -> [String] {
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

        func requireValid(_ item: ModalityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityVariance]) -> [String: [String]] {
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

    static func defaultModalityVarianceValidator() -> ModalityVarianceValidator {
        return ModalityVarianceValidator(
            rules: [
                ModalityVarianceCodeLengthRule(maxLength: 86400),
                ModalityVarianceCodePrefixRule(prefix: "OPS"),
                ModalityVarianceRequiredLabelRule(message: "modality variance needs this field"),
                ModalityVarianceRefillsRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
