import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary formulary batch must pass. Check returns its problems, or none.
    protocol PrimaryFormularyBatchRule {
        func check(_ item: PrimaryFormularyBatch) -> [String]
    }

    final class PrimaryFormularyBatchVisibleGuardRule: PrimaryFormularyBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryFormularyBatch) -> [String] {
            if item.visible && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PrimaryFormularyBatchCodeLengthRule: PrimaryFormularyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFormularyBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryFormularyBatchCodePrefixRule: PrimaryFormularyBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryFormularyBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryFormularyBatchWardLengthRule: PrimaryFormularyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFormularyBatch) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary formulary batch.
    final class PrimaryFormularyBatchValidator {
        var rules: [any PrimaryFormularyBatchRule]

        init(rules: [any PrimaryFormularyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryFormularyBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryFormularyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryFormularyBatch]) -> [String: [String]] {
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

    static func defaultPrimaryFormularyBatchValidator() -> PrimaryFormularyBatchValidator {
        return PrimaryFormularyBatchValidator(
            rules: [
                PrimaryFormularyBatchVisibleGuardRule(limit: 80),
                PrimaryFormularyBatchCodeLengthRule(maxLength: 120),
                PrimaryFormularyBatchCodePrefixRule(prefix: "Q"),
                PrimaryFormularyBatchWardLengthRule(maxLength: 1000),
            ]
        )
    }
}
