import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network reservation is in its life cycle.
    enum NetworkReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a network reservation and its current status.
    final class NetworkReservation {
        var code: String
        var title: String
        var graceDays: Int
        var ownerID: String
        var clinicianID: String
        var sequence: Int
        var approved: Bool
        var status: NetworkReservationStatus

        init(code: String, title: String, graceDays: Int, ownerID: String, clinicianID: String, sequence: Int, approved: Bool, status: NetworkReservationStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.ownerID = ownerID
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkReservationStatus) -> Bool {
            switch status {
            case .created:
                return next == NetworkReservationStatus.validated || next == NetworkReservationStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: NetworkReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("network reservation") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(sequence) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> NetworkReservation {
            return NetworkReservation(
                code: code,
                title: title,
                graceDays: graceDays,
                ownerID: ownerID,
                clinicianID: clinicianID,
                sequence: sequence,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a network reservation in status created.
    static func newNetworkReservation(_ code: String, title: String) -> NetworkReservation {
        return NetworkReservation(
            code: code,
            title: title,
            graceDays: 0,
            ownerID: "",
            clinicianID: "",
            sequence: 0,
            approved: false,
            status: NetworkReservationStatus.created
        )
    }
}
