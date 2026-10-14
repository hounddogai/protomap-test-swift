import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending network policy is in its life cycle.
    enum PendingNetworkPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a pending network policy and its current status.
    final class PendingNetworkPolicy {
        var code: String
        var name: String
        var timezone: String
        var budget: Double
        var ratio: Double
        var procedureCode: String
        var windowDays: Int
        var clinicianID: String
        var locale: String
        var status: PendingNetworkPolicyStatus

        init(code: String, name: String, timezone: String, budget: Double, ratio: Double, procedureCode: String, windowDays: Int, clinicianID: String, locale: String, status: PendingNetworkPolicyStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.budget = budget
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingNetworkPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingNetworkPolicyStatus.archived
            case .inReview:
                return next == PendingNetworkPolicyStatus.reopened || next == PendingNetworkPolicyStatus.archived
            case .resolved:
                return next == PendingNetworkPolicyStatus.reopened || next == PendingNetworkPolicyStatus.archived
            case .reopened:
                return next == PendingNetworkPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingNetworkPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending network policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedTotal() -> Double {
            return (Double(windowDays) * ratio * 100).rounded() / 100
        }

        func copyValue() -> PendingNetworkPolicy {
            return PendingNetworkPolicy(
                code: code,
                name: name,
                timezone: timezone,
                budget: budget,
                ratio: ratio,
                procedureCode: procedureCode,
                windowDays: windowDays,
                clinicianID: clinicianID,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending network policy in status open.
    static func newPendingNetworkPolicy(_ code: String, name: String) -> PendingNetworkPolicy {
        return PendingNetworkPolicy(
            code: code,
            name: name,
            timezone: "",
            budget: 0.0,
            ratio: 0.0,
            procedureCode: "",
            windowDays: 0,
            clinicianID: "",
            locale: "",
            status: PendingNetworkPolicyStatus.`open`
        )
    }
}
