import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered care protocol segment must pass. Check returns its problems, or none.
    protocol TieredCareProtocolSegmentRule {
        func check(_ item: TieredCareProtocolSegment) -> [String]
    }

    final class TieredCareProtocolSegmentRequiredAllergyRule: TieredCareProtocolSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolSegment) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolSegmentRevisionRangeRule: TieredCareProtocolSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareProtocolSegment) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredCareProtocolSegmentLabelLengthRule: TieredCareProtocolSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareProtocolSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care protocol segment.
    final class TieredCareProtocolSegmentValidator {
        var rules: [any TieredCareProtocolSegmentRule]

        init(rules: [any TieredCareProtocolSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareProtocolSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCareProtocolSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareProtocolSegment]) -> [String: [String]] {
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

    static func defaultTieredCareProtocolSegmentValidator() -> TieredCareProtocolSegmentValidator {
        return TieredCareProtocolSegmentValidator(
            rules: [
                TieredCareProtocolSegmentRequiredAllergyRule(message: "tiered care protocol segment needs a value"),
                TieredCareProtocolSegmentRevisionRangeRule(min: 80, max: 255),
                TieredCareProtocolSegmentLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
