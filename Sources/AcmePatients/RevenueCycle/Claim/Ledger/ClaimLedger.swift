import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim ledger is in its life cycle.
    enum ClaimLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a claim ledger and its current status.
    final class ClaimLedger {
        var code: String
        var title: String
        var checksum: String
        var segment: String
        var patientRef: String
        var phone: String
        var amount: Double
        var weight: Double
        var pinned: Bool
        var visitMinutes: Int
        var status: ClaimLedgerStatus

        init(code: String, title: String, checksum: String, segment: String, patientRef: String, phone: String, amount: Double, weight: Double, pinned: Bool, visitMinutes: Int, status: ClaimLedgerStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.segment = segment
            self.patientRef = patientRef
            self.phone = phone
            self.amount = amount
            self.weight = weight
            self.pinned = pinned
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimLedgerStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ClaimLedgerStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("claim ledger") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(visitMinutes) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ClaimLedger {
            return ClaimLedger(
                code: code,
                title: title,
                checksum: checksum,
                segment: segment,
                patientRef: patientRef,
                phone: phone,
                amount: amount,
                weight: weight,
                pinned: pinned,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a claim ledger in status requested.
    static func newClaimLedger(_ code: String, title: String) -> ClaimLedger {
        return ClaimLedger(
            code: code,
            title: title,
            checksum: "",
            segment: "",
            patientRef: "",
            phone: "",
            amount: 0.0,
            weight: 0.0,
            pinned: false,
            visitMinutes: 0,
            status: ClaimLedgerStatus.requested
        )
    }
}
