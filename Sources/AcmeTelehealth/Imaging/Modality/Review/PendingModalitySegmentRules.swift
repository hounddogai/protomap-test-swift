import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending modality segment must pass. Check returns its problems, or none.
    protocol PendingModalitySegmentRule {
        func check(_ item: PendingModalitySegment) -> [String]
    }

    final class PendingModalitySegmentQuantityRangeRule: PendingModalitySegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingModalitySegment) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingModalitySegmentRequiredCodeRule: PendingModalitySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingModalitySegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingModalitySegmentRequiredTitleRule: PendingModalitySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingModalitySegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingModalitySegmentRequiredSpecialtyRule: PendingModalitySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingModalitySegment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingModalitySegmentCodeLengthRule: PendingModalitySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingModalitySegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingModalitySegmentAllowedUnitRule: PendingModalitySegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingModalitySegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a pending modality segment.
    final class PendingModalitySegmentValidator {
        var rules: [any PendingModalitySegmentRule]

        init(rules: [any PendingModalitySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingModalitySegment) -> [String] {
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

        func requireValid(_ item: PendingModalitySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingModalitySegment]) -> [String: [String]] {
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

    static func defaultPendingModalitySegmentValidator() -> PendingModalitySegmentValidator {
        return PendingModalitySegmentValidator(
            rules: [
                PendingModalitySegmentQuantityRangeRule(min: 16, max: 255),
                PendingModalitySegmentRequiredCodeRule(message: "pending modality segment needs an entry"),
                PendingModalitySegmentRequiredTitleRule(message: "pending modality segment needs a value"),
                PendingModalitySegmentRequiredSpecialtyRule(message: "pending modality segment needs this field"),
                PendingModalitySegmentCodeLengthRule(maxLength: 120),
                PendingModalitySegmentAllowedUnitRule(allowed: []),
            ]
        )
    }
}
