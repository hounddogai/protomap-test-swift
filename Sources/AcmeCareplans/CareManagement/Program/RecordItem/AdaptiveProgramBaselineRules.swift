import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive program baseline must pass. Check returns its problems, or none.
    protocol AdaptiveProgramBaselineRule {
        func check(_ item: AdaptiveProgramBaseline) -> [String]
    }

    final class AdaptiveProgramBaselineRequiredTitleRule: AdaptiveProgramBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveProgramBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveProgramBaselineSegmentLengthRule: AdaptiveProgramBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveProgramBaseline) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveProgramBaselineNameLengthRule: AdaptiveProgramBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveProgramBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive program baseline.
    final class AdaptiveProgramBaselineValidator {
        var rules: [any AdaptiveProgramBaselineRule]

        init(rules: [any AdaptiveProgramBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveProgramBaseline) -> [String] {
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

        func requireValid(_ item: AdaptiveProgramBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveProgramBaseline]) -> [String: [String]] {
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

    static func defaultAdaptiveProgramBaselineValidator() -> AdaptiveProgramBaselineValidator {
        return AdaptiveProgramBaselineValidator(
            rules: [
                AdaptiveProgramBaselineRequiredTitleRule(message: "adaptive program baseline needs an entry"),
                AdaptiveProgramBaselineSegmentLengthRule(maxLength: 64),
                AdaptiveProgramBaselineNameLengthRule(maxLength: 80),
            ]
        )
    }
}
