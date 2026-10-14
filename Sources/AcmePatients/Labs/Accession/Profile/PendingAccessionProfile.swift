import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending accession profile is in its life cycle.
    enum PendingAccessionProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending accession profile, with what the planners need to act on it.
    final class PendingAccessionProfile {
        var code: String
        var title: String
        var pinned: Bool
        var segment: String
        var specialty: String
        var payer: String
        var amount: Double
        var facility: String
        var updatedAt: Int
        var approved: Bool
        var status: PendingAccessionProfileStatus

        init(code: String, title: String, pinned: Bool, segment: String, specialty: String, payer: String, amount: Double, facility: String, updatedAt: Int, approved: Bool, status: PendingAccessionProfileStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.segment = segment
            self.specialty = specialty
            self.payer = payer
            self.amount = amount
            self.facility = facility
            self.updatedAt = updatedAt
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingAccessionProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingAccessionProfileStatus.ready || next == PendingAccessionProfileStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingAccessionProfileStatus.draining || next == PendingAccessionProfileStatus.stopped
            case .draining:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingAccessionProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending accession profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending accession profile") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(updatedAt) * amount * 100).rounded() / 100
        }

        func copyValue() -> PendingAccessionProfile {
            return PendingAccessionProfile(
                code: code,
                title: title,
                pinned: pinned,
                segment: segment,
                specialty: specialty,
                payer: payer,
                amount: amount,
                facility: facility,
                updatedAt: updatedAt,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending accession profile in status idle.
    static func newPendingAccessionProfile(_ code: String, title: String) -> PendingAccessionProfile {
        return PendingAccessionProfile(
            code: code,
            title: title,
            pinned: false,
            segment: "",
            specialty: "",
            payer: "",
            amount: 0.0,
            facility: "",
            updatedAt: 0,
            approved: false,
            status: PendingAccessionProfileStatus.idle
        )
    }
}
