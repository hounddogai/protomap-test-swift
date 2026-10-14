import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending transfer notice must pass. Check returns its problems, or none.
    protocol PendingTransferNoticeRule {
        func check(_ item: PendingTransferNotice) -> [String]
    }

    final class PendingTransferNoticeDosageMgRangeRule: PendingTransferNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingTransferNotice) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingTransferNoticeMarginRangeRule: PendingTransferNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingTransferNotice) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingTransferNoticeRequiredLabelRule: PendingTransferNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingTransferNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingTransferNoticeBudgetRangeRule: PendingTransferNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingTransferNotice) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingTransferNoticeCodePrefixRule: PendingTransferNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingTransferNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending transfer notice.
    final class PendingTransferNoticeValidator {
        var rules: [any PendingTransferNoticeRule]

        init(rules: [any PendingTransferNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingTransferNotice) -> [String] {
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

        func requireValid(_ item: PendingTransferNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingTransferNotice]) -> [String: [String]] {
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

    static func defaultPendingTransferNoticeValidator() -> PendingTransferNoticeValidator {
        return PendingTransferNoticeValidator(
            rules: [
                PendingTransferNoticeDosageMgRangeRule(min: 4.9, max: 2108.5),
                PendingTransferNoticeMarginRangeRule(min: 1.7, max: 370.8),
                PendingTransferNoticeRequiredLabelRule(message: "pending transfer notice needs an entry"),
                PendingTransferNoticeBudgetRangeRule(min: 2.8, max: 4013.6),
                PendingTransferNoticeCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
