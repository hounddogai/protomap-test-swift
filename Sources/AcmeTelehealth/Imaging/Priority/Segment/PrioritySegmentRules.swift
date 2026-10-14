import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority segment must pass. Check returns its problems, or none.
    protocol PrioritySegmentRule {
        func check(_ item: PrioritySegment) -> [String]
    }

    final class PrioritySegmentBatchSizeRangeRule: PrioritySegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrioritySegment) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrioritySegmentCodeLengthRule: PrioritySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrioritySegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrioritySegmentAllowedCodeRule: PrioritySegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrioritySegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class PrioritySegmentRequiredSpecialtyRule: PrioritySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrioritySegment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrioritySegmentVisitMinutesRangeRule: PrioritySegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrioritySegment) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrioritySegmentCodePrefixRule: PrioritySegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrioritySegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority segment.
    final class PrioritySegmentValidator {
        var rules: [any PrioritySegmentRule]

        init(rules: [any PrioritySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrioritySegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrioritySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrioritySegment]) -> [String: [String]] {
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

    static func defaultPrioritySegmentValidator() -> PrioritySegmentValidator {
        return PrioritySegmentValidator(
            rules: [
                PrioritySegmentBatchSizeRangeRule(min: 255, max: 255),
                PrioritySegmentCodeLengthRule(maxLength: 80),
                PrioritySegmentAllowedCodeRule(allowed: []),
                PrioritySegmentRequiredSpecialtyRule(message: "priority segment needs an entry"),
                PrioritySegmentVisitMinutesRangeRule(min: 16, max: 3600),
                PrioritySegmentCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
