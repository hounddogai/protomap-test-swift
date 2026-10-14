import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness batch must pass. Check returns its problems, or none.
    protocol WitnessBatchRule {
        func check(_ item: WitnessBatch) -> [String]
    }

    final class WitnessBatchCodePrefixRule: WitnessBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessBatchBatchSizeRangeRule: WitnessBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessBatch) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessBatchLabelLengthRule: WitnessBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessBatchSourceLengthRule: WitnessBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessBatch) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessBatchContactEmailLengthRule: WitnessBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessBatch) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessBatchRequiredContactEmailRule: WitnessBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessBatch) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness batch.
    final class WitnessBatchValidator {
        var rules: [any WitnessBatchRule]

        init(rules: [any WitnessBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessBatch]) -> [String: [String]] {
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

    static func defaultWitnessBatchValidator() -> WitnessBatchValidator {
        return WitnessBatchValidator(
            rules: [
                WitnessBatchCodePrefixRule(prefix: "REF"),
                WitnessBatchBatchSizeRangeRule(min: 80, max: 3600),
                WitnessBatchLabelLengthRule(maxLength: 86400),
                WitnessBatchSourceLengthRule(maxLength: 120),
                WitnessBatchContactEmailLengthRule(maxLength: 32),
                WitnessBatchRequiredContactEmailRule(message: "witness batch needs an entry"),
            ]
        )
    }
}
