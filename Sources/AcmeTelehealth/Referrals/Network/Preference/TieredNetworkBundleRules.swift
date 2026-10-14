import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered network bundle must pass. Check returns its problems, or none.
    protocol TieredNetworkBundleRule {
        func check(_ item: TieredNetworkBundle) -> [String]
    }

    final class TieredNetworkBundleRequiredCodeRule: TieredNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredNetworkBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredNetworkBundleOwnerIDLengthRule: TieredNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredNetworkBundle) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredNetworkBundleSequenceRangeRule: TieredNetworkBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredNetworkBundle) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredNetworkBundleLabelLengthRule: TieredNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredNetworkBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered network bundle.
    final class TieredNetworkBundleValidator {
        var rules: [any TieredNetworkBundleRule]

        init(rules: [any TieredNetworkBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredNetworkBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredNetworkBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredNetworkBundle]) -> [String: [String]] {
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

    static func defaultTieredNetworkBundleValidator() -> TieredNetworkBundleValidator {
        return TieredNetworkBundleValidator(
            rules: [
                TieredNetworkBundleRequiredCodeRule(message: "tiered network bundle needs an entry"),
                TieredNetworkBundleOwnerIDLengthRule(maxLength: 86400),
                TieredNetworkBundleSequenceRangeRule(min: 64, max: 1000),
                TieredNetworkBundleLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
