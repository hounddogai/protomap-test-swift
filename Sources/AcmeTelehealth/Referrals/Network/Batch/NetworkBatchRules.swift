import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network batch must pass. Check returns its problems, or none.
    protocol NetworkBatchRule {
        func check(_ item: NetworkBatch) -> [String]
    }

    final class NetworkBatchAllowedNotesRule: NetworkBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is unknown"]
            }
            return []
        }
    }

    final class NetworkBatchCeilingRangeRule: NetworkBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkBatch) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkBatchCodeLengthRule: NetworkBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network batch.
    final class NetworkBatchValidator {
        var rules: [any NetworkBatchRule]

        init(rules: [any NetworkBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkBatch]) -> [String: [String]] {
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

    static func defaultNetworkBatchValidator() -> NetworkBatchValidator {
        return NetworkBatchValidator(
            rules: [
                NetworkBatchAllowedNotesRule(allowed: ["strict", "fallback", "capped"]),
                NetworkBatchCeilingRangeRule(min: 7.5, max: 1139.1),
                NetworkBatchCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
