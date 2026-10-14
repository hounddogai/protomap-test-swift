import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure draft is in its life cycle.
    enum DisclosureDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A disclosure draft as the disclosure team keeps it.
    final class DisclosureDraft {
        var code: String
        var label: String
        var segment: String
        var ward: String
        var clinicianID: String
        var copay: Double
        var status: DisclosureDraftStatus

        init(code: String, label: String, segment: String, ward: String, clinicianID: String, copay: Double, status: DisclosureDraftStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.ward = ward
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: DisclosureDraftStatus) -> Bool {
            switch status {
            case .requested:
                return next == DisclosureDraftStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: DisclosureDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> DisclosureDraft {
            return DisclosureDraft(
                code: code,
                label: label,
                segment: segment,
                ward: ward,
                clinicianID: clinicianID,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a disclosure draft in status requested.
    static func newDisclosureDraft(_ code: String, label: String) -> DisclosureDraft {
        return DisclosureDraft(
            code: code,
            label: label,
            segment: "",
            ward: "",
            clinicianID: "",
            copay: 0.0,
            status: DisclosureDraftStatus.requested
        )
    }
}
