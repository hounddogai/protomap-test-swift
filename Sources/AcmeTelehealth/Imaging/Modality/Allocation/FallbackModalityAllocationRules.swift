import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback modality allocation must pass. Check returns its problems, or none.
    protocol FallbackModalityAllocationRule {
        func check(_ item: FallbackModalityAllocation) -> [String]
    }

    final class FallbackModalityAllocationRequiredLabelRule: FallbackModalityAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackModalityAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackModalityAllocationCodePrefixRule: FallbackModalityAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackModalityAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackModalityAllocationSourceLengthRule: FallbackModalityAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackModalityAllocation) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackModalityAllocationCeilingRangeRule: FallbackModalityAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackModalityAllocation) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackModalityAllocationChecksumLengthRule: FallbackModalityAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackModalityAllocation) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback modality allocation.
    final class FallbackModalityAllocationValidator {
        var rules: [any FallbackModalityAllocationRule]

        init(rules: [any FallbackModalityAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackModalityAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackModalityAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackModalityAllocation]) -> [String: [String]] {
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

    static func defaultFallbackModalityAllocationValidator() -> FallbackModalityAllocationValidator {
        return FallbackModalityAllocationValidator(
            rules: [
                FallbackModalityAllocationRequiredLabelRule(message: "fallback modality allocation needs this field"),
                FallbackModalityAllocationCodePrefixRule(prefix: "REF"),
                FallbackModalityAllocationSourceLengthRule(maxLength: 16),
                FallbackModalityAllocationCeilingRangeRule(min: 8.5, max: 884.5),
                FallbackModalityAllocationChecksumLengthRule(maxLength: 16),
            ]
        )
    }
}
