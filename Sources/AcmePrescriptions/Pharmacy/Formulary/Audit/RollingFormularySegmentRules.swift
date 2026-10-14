import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling formulary segment must pass. Check returns its problems, or none.
    protocol RollingFormularySegmentRule {
        func check(_ item: RollingFormularySegment) -> [String]
    }

    final class RollingFormularySegmentCodePrefixRule: RollingFormularySegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingFormularySegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingFormularySegmentSpecialtyLengthRule: RollingFormularySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFormularySegment) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingFormularySegmentCodeLengthRule: RollingFormularySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFormularySegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingFormularySegmentVisitMinutesRangeRule: RollingFormularySegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingFormularySegment) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingFormularySegmentChecksumLengthRule: RollingFormularySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFormularySegment) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling formulary segment.
    final class RollingFormularySegmentValidator {
        var rules: [any RollingFormularySegmentRule]

        init(rules: [any RollingFormularySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingFormularySegment) -> [String] {
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

        func requireValid(_ item: RollingFormularySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingFormularySegment]) -> [String: [String]] {
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

    static func defaultRollingFormularySegmentValidator() -> RollingFormularySegmentValidator {
        return RollingFormularySegmentValidator(
            rules: [
                RollingFormularySegmentCodePrefixRule(prefix: "ACM"),
                RollingFormularySegmentSpecialtyLengthRule(maxLength: 32),
                RollingFormularySegmentCodeLengthRule(maxLength: 1000),
                RollingFormularySegmentVisitMinutesRangeRule(min: 16, max: 32),
                RollingFormularySegmentChecksumLengthRule(maxLength: 32),
            ]
        )
    }
}
