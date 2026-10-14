import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol template must pass. Check returns its problems, or none.
    protocol CareProtocolTemplateRule {
        func check(_ item: CareProtocolTemplate) -> [String]
    }

    final class CareProtocolTemplateRequiredLabelRule: CareProtocolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolTemplateBatchSizeRangeRule: CareProtocolTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolTemplateAllowedLabelRule: CareProtocolTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class CareProtocolTemplateSegmentLengthRule: CareProtocolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol template.
    final class CareProtocolTemplateValidator {
        var rules: [any CareProtocolTemplateRule]

        init(rules: [any CareProtocolTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolTemplate]) -> [String: [String]] {
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

    static func defaultCareProtocolTemplateValidator() -> CareProtocolTemplateValidator {
        return CareProtocolTemplateValidator(
            rules: [
                CareProtocolTemplateRequiredLabelRule(message: "care protocol template needs an entry"),
                CareProtocolTemplateBatchSizeRangeRule(min: 32, max: 255),
                CareProtocolTemplateAllowedLabelRule(allowed: ["manual", "global"]),
                CareProtocolTemplateSegmentLengthRule(maxLength: 86400),
            ]
        )
    }
}
