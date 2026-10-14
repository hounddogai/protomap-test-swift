import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap notice must pass. Check returns its problems, or none.
    protocol CareGapNoticeRule {
        func check(_ item: CareGapNotice) -> [String]
    }

    final class CareGapNoticeRequiredCodeRule: CareGapNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapNoticeRequiredFacilityRule: CareGapNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapNotice) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapNoticeRequiredNameRule: CareGapNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapNotice) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapNoticeCreatedAtRangeRule: CareGapNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapNotice) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapNoticeCodeLengthRule: CareGapNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapNoticeNameLengthRule: CareGapNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap notice.
    final class CareGapNoticeValidator {
        var rules: [any CareGapNoticeRule]

        init(rules: [any CareGapNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapNotice) -> [String] {
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

        func requireValid(_ item: CareGapNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapNotice]) -> [String: [String]] {
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

    static func defaultCareGapNoticeValidator() -> CareGapNoticeValidator {
        return CareGapNoticeValidator(
            rules: [
                CareGapNoticeRequiredCodeRule(message: "care gap notice needs this field"),
                CareGapNoticeRequiredFacilityRule(message: "care gap notice needs an entry"),
                CareGapNoticeRequiredNameRule(message: "care gap notice needs this field"),
                CareGapNoticeCreatedAtRangeRule(min: 16, max: 32),
                CareGapNoticeCodeLengthRule(maxLength: 80),
                CareGapNoticeNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
