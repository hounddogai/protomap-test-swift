import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict assessment bundle must pass. Check returns its problems, or none.
    protocol StrictAssessmentBundleRule {
        func check(_ item: StrictAssessmentBundle) -> [String]
    }

    final class StrictAssessmentBundleChannelLengthRule: StrictAssessmentBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAssessmentBundle) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAssessmentBundleCodePrefixRule: StrictAssessmentBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictAssessmentBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictAssessmentBundleRequiredExternalRefRule: StrictAssessmentBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAssessmentBundle) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAssessmentBundleRequiredLabelRule: StrictAssessmentBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAssessmentBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict assessment bundle.
    final class StrictAssessmentBundleValidator {
        var rules: [any StrictAssessmentBundleRule]

        init(rules: [any StrictAssessmentBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAssessmentBundle) -> [String] {
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

        func requireValid(_ item: StrictAssessmentBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAssessmentBundle]) -> [String: [String]] {
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

    static func defaultStrictAssessmentBundleValidator() -> StrictAssessmentBundleValidator {
        return StrictAssessmentBundleValidator(
            rules: [
                StrictAssessmentBundleChannelLengthRule(maxLength: 86400),
                StrictAssessmentBundleCodePrefixRule(prefix: "OPS"),
                StrictAssessmentBundleRequiredExternalRefRule(message: "strict assessment bundle needs an entry"),
                StrictAssessmentBundleRequiredLabelRule(message: "strict assessment bundle needs this field"),
            ]
        )
    }
}
