import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary study score must pass. Check returns its problems, or none.
    protocol PrimaryStudyScoreRule {
        func check(_ item: PrimaryStudyScore) -> [String]
    }

    final class PrimaryStudyScoreLabelLengthRule: PrimaryStudyScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryStudyScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryStudyScoreRequiredLabelRule: PrimaryStudyScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStudyScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryStudyScoreVisibleGuardRule: PrimaryStudyScoreRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryStudyScore) -> [String] {
            if item.visible && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a primary study score.
    final class PrimaryStudyScoreValidator {
        var rules: [any PrimaryStudyScoreRule]

        init(rules: [any PrimaryStudyScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryStudyScore) -> [String] {
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

        func requireValid(_ item: PrimaryStudyScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryStudyScore]) -> [String: [String]] {
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

    static func defaultPrimaryStudyScoreValidator() -> PrimaryStudyScoreValidator {
        return PrimaryStudyScoreValidator(
            rules: [
                PrimaryStudyScoreLabelLengthRule(maxLength: 120),
                PrimaryStudyScoreRequiredLabelRule(message: "primary study score needs a value"),
                PrimaryStudyScoreVisibleGuardRule(limit: 32),
            ]
        )
    }
}
