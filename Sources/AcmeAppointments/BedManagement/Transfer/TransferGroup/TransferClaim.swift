import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer claim is in its life cycle.
    enum TransferClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A transfer claim as the transfer team keeps it.
    final class TransferClaim {
        var code: String
        var label: String
        var threshold: Double
        var score: Double
        var locale: String
        var visible: Bool
        var discount: Double
        var endsAt: Int
        var clinicianID: String
        var status: TransferClaimStatus

        init(code: String, label: String, threshold: Double, score: Double, locale: String, visible: Bool, discount: Double, endsAt: Int, clinicianID: String, status: TransferClaimStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.score = score
            self.locale = locale
            self.visible = visible
            self.discount = discount
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == TransferClaimStatus.scheduled
            case .scheduled:
                return next == TransferClaimStatus.inProgress || next == TransferClaimStatus.completed
            case .inProgress:
                return next == TransferClaimStatus.completed || next == TransferClaimStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TransferClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((threshold + score) * 100).rounded() / 100
        }

        func copyValue() -> TransferClaim {
            return TransferClaim(
                code: code,
                label: label,
                threshold: threshold,
                score: score,
                locale: locale,
                visible: visible,
                discount: discount,
                endsAt: endsAt,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a transfer claim in status planned.
    static func newTransferClaim(_ code: String, label: String) -> TransferClaim {
        return TransferClaim(
            code: code,
            label: label,
            threshold: 0.0,
            score: 0.0,
            locale: "",
            visible: false,
            discount: 0.0,
            endsAt: 0,
            clinicianID: "",
            status: TransferClaimStatus.planned
        )
    }
}
