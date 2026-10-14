import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive care protocol profile is in its life cycle.
    enum AdaptiveCareProtocolProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive care protocol profile. Its code is unique within a tenant.
    final class AdaptiveCareProtocolProfile {
        var code: String
        var title: String
        var dosageMg: Double
        var ownerID: String
        var segment: String
        var facility: String
        var channel: String
        var status: AdaptiveCareProtocolProfileStatus

        init(code: String, title: String, dosageMg: Double, ownerID: String, segment: String, facility: String, channel: String, status: AdaptiveCareProtocolProfileStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.ownerID = ownerID
            self.segment = segment
            self.facility = facility
            self.channel = channel
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

        func canMoveTo(_ next: AdaptiveCareProtocolProfileStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveCareProtocolProfileStatus.rejected || next == AdaptiveCareProtocolProfileStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptiveCareProtocolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care protocol profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> AdaptiveCareProtocolProfile {
            return AdaptiveCareProtocolProfile(
                code: code,
                title: title,
                dosageMg: dosageMg,
                ownerID: ownerID,
                segment: segment,
                facility: facility,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive care protocol profile in status proposed.
    static func newAdaptiveCareProtocolProfile(_ code: String, title: String) -> AdaptiveCareProtocolProfile {
        return AdaptiveCareProtocolProfile(
            code: code,
            title: title,
            dosageMg: 0.0,
            ownerID: "",
            segment: "",
            facility: "",
            channel: "",
            status: AdaptiveCareProtocolProfileStatus.proposed
        )
    }
}
