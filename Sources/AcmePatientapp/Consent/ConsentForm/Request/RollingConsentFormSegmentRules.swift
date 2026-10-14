import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling consent form segment must pass. Check returns its problems, or none.
    protocol RollingConsentFormSegmentRule {
        func check(_ item: RollingConsentFormSegment) -> [String]
    }

    final class RollingConsentFormSegmentRequiredChecksumRule: RollingConsentFormSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormSegment) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormSegmentRequiredCodeRule: RollingConsentFormSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormSegmentLabelLengthRule: RollingConsentFormSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingConsentFormSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingConsentFormSegmentAllowedNameRule: RollingConsentFormSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingConsentFormSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class RollingConsentFormSegmentRequiredLabelRule: RollingConsentFormSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormSegmentRevisionRangeRule: RollingConsentFormSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingConsentFormSegment) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling consent form segment.
    final class RollingConsentFormSegmentValidator {
        var rules: [any RollingConsentFormSegmentRule]

        init(rules: [any RollingConsentFormSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingConsentFormSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingConsentFormSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingConsentFormSegment]) -> [String: [String]] {
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

    static func defaultRollingConsentFormSegmentValidator() -> RollingConsentFormSegmentValidator {
        return RollingConsentFormSegmentValidator(
            rules: [
                RollingConsentFormSegmentRequiredChecksumRule(message: "rolling consent form segment needs an entry"),
                RollingConsentFormSegmentRequiredCodeRule(message: "rolling consent form segment needs a value"),
                RollingConsentFormSegmentLabelLengthRule(maxLength: 255),
                RollingConsentFormSegmentAllowedNameRule(allowed: []),
                RollingConsentFormSegmentRequiredLabelRule(message: "rolling consent form segment needs a value"),
                RollingConsentFormSegmentRevisionRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
