import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer bundle must pass. Check returns its problems, or none.
    protocol TransferBundleRule {
        func check(_ item: TransferBundle) -> [String]
    }

    final class TransferBundleAllowedContactEmailRule: TransferBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is expired"]
            }
            return []
        }
    }

    final class TransferBundleCodePrefixRule: TransferBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferBundleRequiredContactEmailRule: TransferBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferBundle) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferBundleCopayRangeRule: TransferBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferBundle) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferBundleMarginRangeRule: TransferBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferBundle) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer bundle.
    final class TransferBundleValidator {
        var rules: [any TransferBundleRule]

        init(rules: [any TransferBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferBundle]) -> [String: [String]] {
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

    static func defaultTransferBundleValidator() -> TransferBundleValidator {
        return TransferBundleValidator(
            rules: [
                TransferBundleAllowedContactEmailRule(allowed: ["fallback", "lenient", "weighted"]),
                TransferBundleCodePrefixRule(prefix: "Q"),
                TransferBundleRequiredContactEmailRule(message: "transfer bundle needs an entry"),
                TransferBundleCopayRangeRule(min: 7.5, max: 319.7),
                TransferBundleMarginRangeRule(min: 3.5, max: 325.6),
            ]
        )
    }
}
