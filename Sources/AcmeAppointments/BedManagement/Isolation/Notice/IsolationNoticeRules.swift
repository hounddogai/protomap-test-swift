import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation notice must pass. Check returns its problems, or none.
    protocol IsolationNoticeRule {
        func check(_ item: IsolationNotice) -> [String]
    }

    final class IsolationNoticeTitleLengthRule: IsolationNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationNoticeFloorValueRangeRule: IsolationNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationNotice) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationNoticeProcedureCodeLengthRule: IsolationNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationNotice) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation notice.
    final class IsolationNoticeValidator {
        var rules: [any IsolationNoticeRule]

        init(rules: [any IsolationNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationNotice]) -> [String: [String]] {
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

    static func defaultIsolationNoticeValidator() -> IsolationNoticeValidator {
        return IsolationNoticeValidator(
            rules: [
                IsolationNoticeTitleLengthRule(maxLength: 80),
                IsolationNoticeFloorValueRangeRule(min: 7.5, max: 4679.5),
                IsolationNoticeProcedureCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
