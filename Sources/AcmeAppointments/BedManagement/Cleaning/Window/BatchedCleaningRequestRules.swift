import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched cleaning request must pass. Check returns its problems, or none.
    protocol BatchedCleaningRequestRule {
        func check(_ item: BatchedCleaningRequest) -> [String]
    }

    final class BatchedCleaningRequestNameLengthRule: BatchedCleaningRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCleaningRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCleaningRequestAllowedCodeRule: BatchedCleaningRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCleaningRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class BatchedCleaningRequestQuantityRangeRule: BatchedCleaningRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCleaningRequest) -> [String] {
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

    final class BatchedCleaningRequestPhoneLengthRule: BatchedCleaningRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCleaningRequest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCleaningRequestCodePrefixRule: BatchedCleaningRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedCleaningRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedCleaningRequestSummaryLengthRule: BatchedCleaningRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCleaningRequest) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched cleaning request.
    final class BatchedCleaningRequestValidator {
        var rules: [any BatchedCleaningRequestRule]

        init(rules: [any BatchedCleaningRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCleaningRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedCleaningRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCleaningRequest]) -> [String: [String]] {
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

    static func defaultBatchedCleaningRequestValidator() -> BatchedCleaningRequestValidator {
        return BatchedCleaningRequestValidator(
            rules: [
                BatchedCleaningRequestNameLengthRule(maxLength: 16),
                BatchedCleaningRequestAllowedCodeRule(allowed: []),
                BatchedCleaningRequestQuantityRangeRule(min: 80, max: 255),
                BatchedCleaningRequestPhoneLengthRule(maxLength: 1000),
                BatchedCleaningRequestCodePrefixRule(prefix: "OPS"),
                BatchedCleaningRequestSummaryLengthRule(maxLength: 64),
            ]
        )
    }
}
