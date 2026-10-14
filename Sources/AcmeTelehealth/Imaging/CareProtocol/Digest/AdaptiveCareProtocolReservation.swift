import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive care protocol reservation is in its life cycle.
    enum AdaptiveCareProtocolReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive care protocol reservation. Its code is unique within a tenant.
    final class AdaptiveCareProtocolReservation {
        var code: String
        var name: String
        var visitMinutes: Int
        var archived: Bool
        var sequence: Int
        var startsAt: Int
        var clinicianID: String
        var visible: Bool
        var status: AdaptiveCareProtocolReservationStatus

        init(code: String, name: String, visitMinutes: Int, archived: Bool, sequence: Int, startsAt: Int, clinicianID: String, visible: Bool, status: AdaptiveCareProtocolReservationStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.sequence = sequence
            self.startsAt = startsAt
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

        func canMoveTo(_ next: AdaptiveCareProtocolReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveCareProtocolReservationStatus.granted || next == AdaptiveCareProtocolReservationStatus.revoked
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

        func moveTo(_ next: AdaptiveCareProtocolReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care protocol reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return (Double(visitMinutes) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCareProtocolReservation {
            return AdaptiveCareProtocolReservation(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                archived: archived,
                sequence: sequence,
                startsAt: startsAt,
                clinicianID: clinicianID,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive care protocol reservation in status requested.
    static func newAdaptiveCareProtocolReservation(_ code: String, name: String) -> AdaptiveCareProtocolReservation {
        return AdaptiveCareProtocolReservation(
            code: code,
            name: name,
            visitMinutes: 0,
            archived: false,
            sequence: 0,
            startsAt: 0,
            clinicianID: "",
            visible: false,
            status: AdaptiveCareProtocolReservationStatus.requested
        )
    }
}
