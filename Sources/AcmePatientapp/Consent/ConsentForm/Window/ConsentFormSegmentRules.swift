import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form segment must pass. Check returns its problems, or none.
    protocol ConsentFormSegmentRule {
        func check(_ item: ConsentFormSegment) -> [String]
    }

    final class ConsentFormSegmentRequiredCodeRule: ConsentFormSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormSegmentRequiredLabelRule: ConsentFormSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormSegmentDosageMgRangeRule: ConsentFormSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormSegment) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormSegmentRegionLengthRule: ConsentFormSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSegment) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormSegmentLabelLengthRule: ConsentFormSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormSegmentLocaleLengthRule: ConsentFormSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSegment) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form segment.
    final class ConsentFormSegmentValidator {
        var rules: [any ConsentFormSegmentRule]

        init(rules: [any ConsentFormSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormSegment) -> [String] {
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

        func requireValid(_ item: ConsentFormSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormSegment]) -> [String: [String]] {
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

    static func defaultConsentFormSegmentValidator() -> ConsentFormSegmentValidator {
        return ConsentFormSegmentValidator(
            rules: [
                ConsentFormSegmentRequiredCodeRule(message: "consent form segment needs a value"),
                ConsentFormSegmentRequiredLabelRule(message: "consent form segment needs a value"),
                ConsentFormSegmentDosageMgRangeRule(min: 5.6, max: 4407.4),
                ConsentFormSegmentRegionLengthRule(maxLength: 64),
                ConsentFormSegmentLabelLengthRule(maxLength: 86400),
                ConsentFormSegmentLocaleLengthRule(maxLength: 80),
            ]
        )
    }
}
