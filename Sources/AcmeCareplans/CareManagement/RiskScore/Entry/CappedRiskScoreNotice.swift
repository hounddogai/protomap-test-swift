import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped risk score notice is in its life cycle.
    enum CappedRiskScoreNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a capped risk score notice and its current status.
    final class CappedRiskScoreNotice {
        var code: String
        var label: String
        var priority: Int
        var quantity: Int
        var ward: String
        var channel: String
        var refills: Int
        var bed: String
        var clinicianID: String
        var visible: Bool
        var status: CappedRiskScoreNoticeStatus

        init(code: String, label: String, priority: Int, quantity: Int, ward: String, channel: String, refills: Int, bed: String, clinicianID: String, visible: Bool, status: CappedRiskScoreNoticeStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.quantity = quantity
            self.ward = ward
            self.channel = channel
            self.refills = refills
            self.bed = bed
            self.clinicianID = clinicianID
            self.visible = visible
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

        func canMoveTo(_ next: CappedRiskScoreNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedRiskScoreNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped risk score notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return ((Double(priority) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> CappedRiskScoreNotice {
            return CappedRiskScoreNotice(
                code: code,
                label: label,
                priority: priority,
                quantity: quantity,
                ward: ward,
                channel: channel,
                refills: refills,
                bed: bed,
                clinicianID: clinicianID,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped risk score notice in status requested.
    static func newCappedRiskScoreNotice(_ code: String, label: String) -> CappedRiskScoreNotice {
        return CappedRiskScoreNotice(
            code: code,
            label: label,
            priority: 0,
            quantity: 0,
            ward: "",
            channel: "",
            refills: 0,
            bed: "",
            clinicianID: "",
            visible: false,
            status: CappedRiskScoreNoticeStatus.requested
        )
    }
}
