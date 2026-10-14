import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered transfer bundle must pass. Check returns its problems, or none.
    protocol TieredTransferBundleRule {
        func check(_ item: TieredTransferBundle) -> [String]
    }

    final class TieredTransferBundleRequiredSpecialtyRule: TieredTransferBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTransferBundle) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTransferBundleCodePrefixRule: TieredTransferBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredTransferBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredTransferBundleLocaleLengthRule: TieredTransferBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTransferBundle) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered transfer bundle.
    final class TieredTransferBundleValidator {
        var rules: [any TieredTransferBundleRule]

        init(rules: [any TieredTransferBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredTransferBundle) -> [String] {
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

        func requireValid(_ item: TieredTransferBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredTransferBundle]) -> [String: [String]] {
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

    static func defaultTieredTransferBundleValidator() -> TieredTransferBundleValidator {
        return TieredTransferBundleValidator(
            rules: [
                TieredTransferBundleRequiredSpecialtyRule(message: "tiered transfer bundle needs this field"),
                TieredTransferBundleCodePrefixRule(prefix: "ACM"),
                TieredTransferBundleLocaleLengthRule(maxLength: 3600),
            ]
        )
    }
}
