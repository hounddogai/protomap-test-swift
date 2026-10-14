import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan item must pass. Check returns its problems, or none.
    protocol AcuityPlanItemRule {
        func check(_ item: AcuityPlanItem) -> [String]
    }

    final class AcuityPlanItemTitleLengthRule: AcuityPlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanItem) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanItemPriorityRangeRule: AcuityPlanItemRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanItem) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanItemRequiredCodeRule: AcuityPlanItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanItem) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanItemDescriptionLengthRule: AcuityPlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanItem) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanItemSegmentLengthRule: AcuityPlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanItem) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan item.
    final class AcuityPlanItemValidator {
        var rules: [any AcuityPlanItemRule]

        init(rules: [any AcuityPlanItemRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanItem) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanItem]) -> [String: [String]] {
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

    static func defaultAcuityPlanItemValidator() -> AcuityPlanItemValidator {
        return AcuityPlanItemValidator(
            rules: [
                AcuityPlanItemTitleLengthRule(maxLength: 120),
                AcuityPlanItemPriorityRangeRule(min: 16, max: 86400),
                AcuityPlanItemRequiredCodeRule(message: "acuity plan item needs this field"),
                AcuityPlanItemDescriptionLengthRule(maxLength: 1000),
                AcuityPlanItemSegmentLengthRule(maxLength: 16),
            ]
        )
    }
}
