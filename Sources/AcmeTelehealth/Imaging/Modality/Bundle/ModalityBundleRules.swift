import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality bundle must pass. Check returns its problems, or none.
    protocol ModalityBundleRule {
        func check(_ item: ModalityBundle) -> [String]
    }

    final class ModalityBundleCodePrefixRule: ModalityBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityBundleRequiredLabelRule: ModalityBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityBundleRequiredCodeRule: ModalityBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityBundleCodeLengthRule: ModalityBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityBundleMinimumRangeRule: ModalityBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityBundle) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality bundle.
    final class ModalityBundleValidator {
        var rules: [any ModalityBundleRule]

        init(rules: [any ModalityBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityBundle]) -> [String: [String]] {
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

    static func defaultModalityBundleValidator() -> ModalityBundleValidator {
        return ModalityBundleValidator(
            rules: [
                ModalityBundleCodePrefixRule(prefix: "ACM"),
                ModalityBundleRequiredLabelRule(message: "modality bundle needs this field"),
                ModalityBundleRequiredCodeRule(message: "modality bundle needs an entry"),
                ModalityBundleCodeLengthRule(maxLength: 64),
                ModalityBundleMinimumRangeRule(min: 4.0, max: 1167.6),
            ]
        )
    }
}
