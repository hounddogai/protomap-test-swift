import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive network ledger is in its life cycle.
    enum AdaptiveNetworkLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a adaptive network ledger and its current status.
    final class AdaptiveNetworkLedger {
        var code: String
        var name: String
        var label: String
        var ownerID: String
        var visitMinutes: Int
        var ratio: Double
        var endsAt: Int
        var graceDays: Int
        var specialty: String
        var status: AdaptiveNetworkLedgerStatus

        init(code: String, name: String, label: String, ownerID: String, visitMinutes: Int, ratio: Double, endsAt: Int, graceDays: Int, specialty: String, status: AdaptiveNetworkLedgerStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.ownerID = ownerID
            self.visitMinutes = visitMinutes
            self.ratio = ratio
            self.endsAt = endsAt
            self.graceDays = graceDays
            self.specialty = specialty
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

        func canMoveTo(_ next: AdaptiveNetworkLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveNetworkLedgerStatus.archived
            case .resolved:
                return next == AdaptiveNetworkLedgerStatus.reopened || next == AdaptiveNetworkLedgerStatus.archived
            case .reopened:
                return next == AdaptiveNetworkLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveNetworkLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive network ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive network ledger") \(code)"
        }

        func projectedVolume() -> Double {
            return ((ratio + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveNetworkLedger {
            return AdaptiveNetworkLedger(
                code: code,
                name: name,
                label: label,
                ownerID: ownerID,
                visitMinutes: visitMinutes,
                ratio: ratio,
                endsAt: endsAt,
                graceDays: graceDays,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive network ledger in status open.
    static func newAdaptiveNetworkLedger(_ code: String, name: String) -> AdaptiveNetworkLedger {
        return AdaptiveNetworkLedger(
            code: code,
            name: name,
            label: "",
            ownerID: "",
            visitMinutes: 0,
            ratio: 0.0,
            endsAt: 0,
            graceDays: 0,
            specialty: "",
            status: AdaptiveNetworkLedgerStatus.`open`
        )
    }
}
