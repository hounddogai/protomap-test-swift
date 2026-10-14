import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive modality request must pass. Check returns its problems, or none.
    protocol AdaptiveModalityRequestRule {
        func check(_ item: AdaptiveModalityRequest) -> [String]
    }

    final class AdaptiveModalityRequestNameLengthRule: AdaptiveModalityRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveModalityRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveModalityRequestRequiredDiagnosisCodeRule: AdaptiveModalityRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveModalityRequest) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveModalityRequestStartsAtRangeRule: AdaptiveModalityRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveModalityRequest) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveModalityRequestAllowedTitleRule: AdaptiveModalityRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveModalityRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class AdaptiveModalityRequestSummaryLengthRule: AdaptiveModalityRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveModalityRequest) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveModalityRequestDiagnosisCodeLengthRule: AdaptiveModalityRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveModalityRequest) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive modality request.
    final class AdaptiveModalityRequestValidator {
        var rules: [any AdaptiveModalityRequestRule]

        init(rules: [any AdaptiveModalityRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveModalityRequest) -> [String] {
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

        func requireValid(_ item: AdaptiveModalityRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveModalityRequest]) -> [String: [String]] {
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

    static func defaultAdaptiveModalityRequestValidator() -> AdaptiveModalityRequestValidator {
        return AdaptiveModalityRequestValidator(
            rules: [
                AdaptiveModalityRequestNameLengthRule(maxLength: 16),
                AdaptiveModalityRequestRequiredDiagnosisCodeRule(message: "adaptive modality request needs an entry"),
                AdaptiveModalityRequestStartsAtRangeRule(min: 16, max: 3600),
                AdaptiveModalityRequestAllowedTitleRule(allowed: ["strict"]),
                AdaptiveModalityRequestSummaryLengthRule(maxLength: 16),
                AdaptiveModalityRequestDiagnosisCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
