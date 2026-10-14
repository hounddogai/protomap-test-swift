import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation batch must pass. Check returns its problems, or none.
    protocol IsolationBatchRule {
        func check(_ item: IsolationBatch) -> [String]
    }

    final class IsolationBatchRequiredCodeRule: IsolationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationBatchRequiredLabelRule: IsolationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationBatchCodeLengthRule: IsolationBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationBatchChecksumLengthRule: IsolationBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationBatch) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationBatchRequiredChecksumRule: IsolationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationBatch) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationBatchCodePrefixRule: IsolationBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation batch.
    final class IsolationBatchValidator {
        var rules: [any IsolationBatchRule]

        init(rules: [any IsolationBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationBatch]) -> [String: [String]] {
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

    static func defaultIsolationBatchValidator() -> IsolationBatchValidator {
        return IsolationBatchValidator(
            rules: [
                IsolationBatchRequiredCodeRule(message: "isolation batch needs a value"),
                IsolationBatchRequiredLabelRule(message: "isolation batch needs an entry"),
                IsolationBatchCodeLengthRule(maxLength: 32),
                IsolationBatchChecksumLengthRule(maxLength: 64),
                IsolationBatchRequiredChecksumRule(message: "isolation batch needs a value"),
                IsolationBatchCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
