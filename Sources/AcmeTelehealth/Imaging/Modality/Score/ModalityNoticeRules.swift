import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality notice must pass. Check returns its problems, or none.
    protocol ModalityNoticeRule {
        func check(_ item: ModalityNotice) -> [String]
    }

    final class ModalityNoticeRequiredContactEmailRule: ModalityNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityNotice) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityNoticeRequiredLabelRule: ModalityNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityNoticeApprovedGuardRule: ModalityNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ModalityNotice) -> [String] {
            if item.approved && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ModalityNoticeLabelLengthRule: ModalityNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityNoticeCodeLengthRule: ModalityNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityNoticeVersionRangeRule: ModalityNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityNotice) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a modality notice.
    final class ModalityNoticeValidator {
        var rules: [any ModalityNoticeRule]

        init(rules: [any ModalityNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityNotice]) -> [String: [String]] {
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

    static func defaultModalityNoticeValidator() -> ModalityNoticeValidator {
        return ModalityNoticeValidator(
            rules: [
                ModalityNoticeRequiredContactEmailRule(message: "modality notice needs a value"),
                ModalityNoticeRequiredLabelRule(message: "modality notice needs a value"),
                ModalityNoticeApprovedGuardRule(limit: 120),
                ModalityNoticeLabelLengthRule(maxLength: 3600),
                ModalityNoticeCodeLengthRule(maxLength: 120),
                ModalityNoticeVersionRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
