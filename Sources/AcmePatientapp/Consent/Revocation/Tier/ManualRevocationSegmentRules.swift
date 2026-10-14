import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual revocation segment must pass. Check returns its problems, or none.
    protocol ManualRevocationSegmentRule {
        func check(_ item: ManualRevocationSegment) -> [String]
    }

    final class ManualRevocationSegmentRequiredCodeRule: ManualRevocationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRevocationSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRevocationSegmentCodePrefixRule: ManualRevocationSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualRevocationSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualRevocationSegmentRequiredBedRule: ManualRevocationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRevocationSegment) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRevocationSegmentRequiredNameRule: ManualRevocationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRevocationSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRevocationSegmentBatchSizeRangeRule: ManualRevocationSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRevocationSegment) -> [String] {
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

    /// Runs every rule of a manual revocation segment.
    final class ManualRevocationSegmentValidator {
        var rules: [any ManualRevocationSegmentRule]

        init(rules: [any ManualRevocationSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRevocationSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRevocationSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRevocationSegment]) -> [String: [String]] {
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

    static func defaultManualRevocationSegmentValidator() -> ManualRevocationSegmentValidator {
        return ManualRevocationSegmentValidator(
            rules: [
                ManualRevocationSegmentRequiredCodeRule(message: "manual revocation segment needs an entry"),
                ManualRevocationSegmentCodePrefixRule(prefix: "ACM"),
                ManualRevocationSegmentRequiredBedRule(message: "manual revocation segment needs an entry"),
                ManualRevocationSegmentRequiredNameRule(message: "manual revocation segment needs this field"),
                ManualRevocationSegmentBatchSizeRangeRule(min: 16, max: 16),
            ]
        )
    }
}
