import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending result preference is in its life cycle.
    enum PendingResultPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending result preference, with what the planners need to act on it.
    final class PendingResultPreference {
        var code: String
        var label: String
        var phone: String
        var pinned: Bool
        var ward: String
        var endsAt: Int
        var summary: String
        var floorValue: Double
        var visible: Bool
        var refills: Int
        var status: PendingResultPreferenceStatus

        init(code: String, label: String, phone: String, pinned: Bool, ward: String, endsAt: Int, summary: String, floorValue: Double, visible: Bool, refills: Int, status: PendingResultPreferenceStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.pinned = pinned
            self.ward = ward
            self.endsAt = endsAt
            self.summary = summary
            self.floorValue = floorValue
            self.visible = visible
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingResultPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingResultPreferenceStatus.approved || next == PendingResultPreferenceStatus.rejected
            case .approved:
                return next == PendingResultPreferenceStatus.rejected || next == PendingResultPreferenceStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PendingResultPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending result preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending result preference") \(code)"
        }

        func weightedExposure() -> Double {
            return ((floorValue + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PendingResultPreference {
            return PendingResultPreference(
                code: code,
                label: label,
                phone: phone,
                pinned: pinned,
                ward: ward,
                endsAt: endsAt,
                summary: summary,
                floorValue: floorValue,
                visible: visible,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending result preference in status proposed.
    static func newPendingResultPreference(_ code: String, label: String) -> PendingResultPreference {
        return PendingResultPreference(
            code: code,
            label: label,
            phone: "",
            pinned: false,
            ward: "",
            endsAt: 0,
            summary: "",
            floorValue: 0.0,
            visible: false,
            refills: 0,
            status: PendingResultPreferenceStatus.proposed
        )
    }
}
