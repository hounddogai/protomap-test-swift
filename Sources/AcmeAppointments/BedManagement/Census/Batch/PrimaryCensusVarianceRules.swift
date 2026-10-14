import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary census variance must pass. Check returns its problems, or none.
    protocol PrimaryCensusVarianceRule {
        func check(_ item: PrimaryCensusVariance) -> [String]
    }

    final class PrimaryCensusVarianceRequiredLabelRule: PrimaryCensusVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCensusVarianceRequiredContactEmailRule: PrimaryCensusVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusVariance) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCensusVarianceRequiredCodeRule: PrimaryCensusVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCensusVarianceAllowedContactEmailRule: PrimaryCensusVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryCensusVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is above maximum"]
            }
            return []
        }
    }

    final class PrimaryCensusVarianceLabelLengthRule: PrimaryCensusVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCensusVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCensusVarianceCodeLengthRule: PrimaryCensusVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCensusVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary census variance.
    final class PrimaryCensusVarianceValidator {
        var rules: [any PrimaryCensusVarianceRule]

        init(rules: [any PrimaryCensusVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCensusVariance) -> [String] {
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

        func requireValid(_ item: PrimaryCensusVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCensusVariance]) -> [String: [String]] {
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

    static func defaultPrimaryCensusVarianceValidator() -> PrimaryCensusVarianceValidator {
        return PrimaryCensusVarianceValidator(
            rules: [
                PrimaryCensusVarianceRequiredLabelRule(message: "primary census variance needs a value"),
                PrimaryCensusVarianceRequiredContactEmailRule(message: "primary census variance needs an entry"),
                PrimaryCensusVarianceRequiredCodeRule(message: "primary census variance needs this field"),
                PrimaryCensusVarianceAllowedContactEmailRule(allowed: ["rolling", "strict"]),
                PrimaryCensusVarianceLabelLengthRule(maxLength: 16),
                PrimaryCensusVarianceCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
