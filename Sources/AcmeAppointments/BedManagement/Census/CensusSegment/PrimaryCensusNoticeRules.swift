import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary census notice must pass. Check returns its problems, or none.
    protocol PrimaryCensusNoticeRule {
        func check(_ item: PrimaryCensusNotice) -> [String]
    }

    final class PrimaryCensusNoticeReviewerLengthRule: PrimaryCensusNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCensusNotice) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCensusNoticeCopayRangeRule: PrimaryCensusNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCensusNotice) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryCensusNoticeRequiredOwnerIDRule: PrimaryCensusNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusNotice) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCensusNoticeRequiredLabelRule: PrimaryCensusNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCensusNoticeActiveGuardRule: PrimaryCensusNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryCensusNotice) -> [String] {
            if item.active && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class PrimaryCensusNoticeAllowedOwnerIDRule: PrimaryCensusNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryCensusNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a primary census notice.
    final class PrimaryCensusNoticeValidator {
        var rules: [any PrimaryCensusNoticeRule]

        init(rules: [any PrimaryCensusNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCensusNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryCensusNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCensusNotice]) -> [String: [String]] {
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

    static func defaultPrimaryCensusNoticeValidator() -> PrimaryCensusNoticeValidator {
        return PrimaryCensusNoticeValidator(
            rules: [
                PrimaryCensusNoticeReviewerLengthRule(maxLength: 255),
                PrimaryCensusNoticeCopayRangeRule(min: 1.5, max: 2668.5),
                PrimaryCensusNoticeRequiredOwnerIDRule(message: "primary census notice needs this field"),
                PrimaryCensusNoticeRequiredLabelRule(message: "primary census notice needs an entry"),
                PrimaryCensusNoticeActiveGuardRule(limit: 86400),
                PrimaryCensusNoticeAllowedOwnerIDRule(allowed: ["manual", "fallback", "fallback"]),
            ]
        )
    }
}
