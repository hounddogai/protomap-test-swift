import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending program notice must pass. Check returns its problems, or none.
    protocol PendingProgramNoticeRule {
        func check(_ item: PendingProgramNotice) -> [String]
    }

    final class PendingProgramNoticeRequiredLabelRule: PendingProgramNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingProgramNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingProgramNoticeNameLengthRule: PendingProgramNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingProgramNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingProgramNoticeLabelLengthRule: PendingProgramNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingProgramNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingProgramNoticeMarginRangeRule: PendingProgramNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingProgramNotice) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending program notice.
    final class PendingProgramNoticeValidator {
        var rules: [any PendingProgramNoticeRule]

        init(rules: [any PendingProgramNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingProgramNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingProgramNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingProgramNotice]) -> [String: [String]] {
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

    static func defaultPendingProgramNoticeValidator() -> PendingProgramNoticeValidator {
        return PendingProgramNoticeValidator(
            rules: [
                PendingProgramNoticeRequiredLabelRule(message: "pending program notice needs a value"),
                PendingProgramNoticeNameLengthRule(maxLength: 32),
                PendingProgramNoticeLabelLengthRule(maxLength: 86400),
                PendingProgramNoticeMarginRangeRule(min: 9.6, max: 695.8),
            ]
        )
    }
}
