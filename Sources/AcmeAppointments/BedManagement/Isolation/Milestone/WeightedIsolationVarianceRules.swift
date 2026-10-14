import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted isolation variance must pass. Check returns its problems, or none.
    protocol WeightedIsolationVarianceRule {
        func check(_ item: WeightedIsolationVariance) -> [String]
    }

    final class WeightedIsolationVarianceTitleLengthRule: WeightedIsolationVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedIsolationVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedIsolationVarianceRequiredLabelRule: WeightedIsolationVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedIsolationVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedIsolationVarianceCodePrefixRule: WeightedIsolationVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedIsolationVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedIsolationVarianceRequiredClinicianIDRule: WeightedIsolationVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedIsolationVariance) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedIsolationVarianceAllowedTitleRule: WeightedIsolationVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedIsolationVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class WeightedIsolationVarianceRequiredCodeRule: WeightedIsolationVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedIsolationVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted isolation variance.
    final class WeightedIsolationVarianceValidator {
        var rules: [any WeightedIsolationVarianceRule]

        init(rules: [any WeightedIsolationVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedIsolationVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedIsolationVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedIsolationVariance]) -> [String: [String]] {
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

    static func defaultWeightedIsolationVarianceValidator() -> WeightedIsolationVarianceValidator {
        return WeightedIsolationVarianceValidator(
            rules: [
                WeightedIsolationVarianceTitleLengthRule(maxLength: 255),
                WeightedIsolationVarianceRequiredLabelRule(message: "weighted isolation variance needs a value"),
                WeightedIsolationVarianceCodePrefixRule(prefix: "ACM"),
                WeightedIsolationVarianceRequiredClinicianIDRule(
                    message: "weighted isolation variance needs an entry"
                ),
                WeightedIsolationVarianceAllowedTitleRule(allowed: []),
                WeightedIsolationVarianceRequiredCodeRule(message: "weighted isolation variance needs this field"),
            ]
        )
    }
}
