import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped modality request must pass. Check returns its problems, or none.
    protocol CappedModalityRequestRule {
        func check(_ item: CappedModalityRequest) -> [String]
    }

    final class CappedModalityRequestCodeLengthRule: CappedModalityRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedModalityRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedModalityRequestBedLengthRule: CappedModalityRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedModalityRequest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedModalityRequestCodePrefixRule: CappedModalityRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedModalityRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedModalityRequestRequiredDescriptionRule: CappedModalityRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedModalityRequest) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedModalityRequestAllowedBedRule: CappedModalityRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedModalityRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is expired"]
            }
            return []
        }
    }

    final class CappedModalityRequestRateRangeRule: CappedModalityRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedModalityRequest) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped modality request.
    final class CappedModalityRequestValidator {
        var rules: [any CappedModalityRequestRule]

        init(rules: [any CappedModalityRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedModalityRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedModalityRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedModalityRequest]) -> [String: [String]] {
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

    static func defaultCappedModalityRequestValidator() -> CappedModalityRequestValidator {
        return CappedModalityRequestValidator(
            rules: [
                CappedModalityRequestCodeLengthRule(maxLength: 3600),
                CappedModalityRequestBedLengthRule(maxLength: 16),
                CappedModalityRequestCodePrefixRule(prefix: "X"),
                CappedModalityRequestRequiredDescriptionRule(message: "capped modality request needs this field"),
                CappedModalityRequestAllowedBedRule(allowed: []),
                CappedModalityRequestRateRangeRule(min: 7.7, max: 3925.3),
            ]
        )
    }
}
