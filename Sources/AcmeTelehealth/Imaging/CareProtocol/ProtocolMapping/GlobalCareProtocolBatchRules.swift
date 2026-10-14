import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global care protocol batch must pass. Check returns its problems, or none.
    protocol GlobalCareProtocolBatchRule {
        func check(_ item: GlobalCareProtocolBatch) -> [String]
    }

    final class GlobalCareProtocolBatchCodePrefixRule: GlobalCareProtocolBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCareProtocolBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCareProtocolBatchSegmentLengthRule: GlobalCareProtocolBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareProtocolBatch) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCareProtocolBatchDiscountRangeRule: GlobalCareProtocolBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareProtocolBatch) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalCareProtocolBatchRequiredSegmentRule: GlobalCareProtocolBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolBatch) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareProtocolBatchRequiredPhoneRule: GlobalCareProtocolBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolBatch) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareProtocolBatchRequiredCodeRule: GlobalCareProtocolBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global care protocol batch.
    final class GlobalCareProtocolBatchValidator {
        var rules: [any GlobalCareProtocolBatchRule]

        init(rules: [any GlobalCareProtocolBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareProtocolBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCareProtocolBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareProtocolBatch]) -> [String: [String]] {
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

    static func defaultGlobalCareProtocolBatchValidator() -> GlobalCareProtocolBatchValidator {
        return GlobalCareProtocolBatchValidator(
            rules: [
                GlobalCareProtocolBatchCodePrefixRule(prefix: "ACM"),
                GlobalCareProtocolBatchSegmentLengthRule(maxLength: 86400),
                GlobalCareProtocolBatchDiscountRangeRule(min: 4.2, max: 4507.0),
                GlobalCareProtocolBatchRequiredSegmentRule(message: "global care protocol batch needs this field"),
                GlobalCareProtocolBatchRequiredPhoneRule(message: "global care protocol batch needs an entry"),
                GlobalCareProtocolBatchRequiredCodeRule(message: "global care protocol batch needs this field"),
            ]
        )
    }
}
