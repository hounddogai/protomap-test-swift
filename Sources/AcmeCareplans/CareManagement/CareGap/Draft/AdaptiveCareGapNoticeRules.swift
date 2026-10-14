import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive care gap notice must pass. Check returns its problems, or none.
    protocol AdaptiveCareGapNoticeRule {
        func check(_ item: AdaptiveCareGapNotice) -> [String]
    }

    final class AdaptiveCareGapNoticeSpecialtyLengthRule: AdaptiveCareGapNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareGapNotice) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareGapNoticeRequiredSpecialtyRule: AdaptiveCareGapNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareGapNotice) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCareGapNoticeApprovedGuardRule: AdaptiveCareGapNoticeRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AdaptiveCareGapNotice) -> [String] {
            if item.approved && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class AdaptiveCareGapNoticeScoreRangeRule: AdaptiveCareGapNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCareGapNotice) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive care gap notice.
    final class AdaptiveCareGapNoticeValidator {
        var rules: [any AdaptiveCareGapNoticeRule]

        init(rules: [any AdaptiveCareGapNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareGapNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCareGapNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareGapNotice]) -> [String: [String]] {
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

    static func defaultAdaptiveCareGapNoticeValidator() -> AdaptiveCareGapNoticeValidator {
        return AdaptiveCareGapNoticeValidator(
            rules: [
                AdaptiveCareGapNoticeSpecialtyLengthRule(maxLength: 64),
                AdaptiveCareGapNoticeRequiredSpecialtyRule(message: "adaptive care gap notice needs an entry"),
                AdaptiveCareGapNoticeApprovedGuardRule(limit: 6.4),
                AdaptiveCareGapNoticeScoreRangeRule(min: 5.2, max: 585.2),
            ]
        )
    }
}
