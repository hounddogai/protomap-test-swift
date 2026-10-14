import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim batch is in its life cycle.
    enum ClaimBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One claim batch, with what the planners need to act on it.
    final class ClaimBatch {
        var code: String
        var title: String
        var ownerID: String
        var quantity: Int
        var approved: Bool
        var windowDays: Int
        var source: String
        var label: String
        var startsAt: Int
        var copay: Double
        var status: ClaimBatchStatus

        init(code: String, title: String, ownerID: String, quantity: Int, approved: Bool, windowDays: Int, source: String, label: String, startsAt: Int, copay: Double, status: ClaimBatchStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.quantity = quantity
            self.approved = approved
            self.windowDays = windowDays
            self.source = source
            self.label = label
            self.startsAt = startsAt
            self.copay = copay
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

        func canMoveTo(_ next: ClaimBatchStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ClaimBatchStatus.revoked || next == ClaimBatchStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ClaimBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("claim batch") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(quantity) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ClaimBatch {
            return ClaimBatch(
                code: code,
                title: title,
                ownerID: ownerID,
                quantity: quantity,
                approved: approved,
                windowDays: windowDays,
                source: source,
                label: label,
                startsAt: startsAt,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a claim batch in status requested.
    static func newClaimBatch(_ code: String, title: String) -> ClaimBatch {
        return ClaimBatch(
            code: code,
            title: title,
            ownerID: "",
            quantity: 0,
            approved: false,
            windowDays: 0,
            source: "",
            label: "",
            startsAt: 0,
            copay: 0.0,
            status: ClaimBatchStatus.requested
        )
    }
}
