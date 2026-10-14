import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual care protocol reservation is in its life cycle.
    enum ManualCareProtocolReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One manual care protocol reservation, with what the planners need to act on it.
    final class ManualCareProtocolReservation {
        var code: String
        var label: String
        var name: String
        var reviewer: String
        var floorValue: Double
        var sequence: Int
        var weight: Double
        var status: ManualCareProtocolReservationStatus

        init(code: String, label: String, name: String, reviewer: String, floorValue: Double, sequence: Int, weight: Double, status: ManualCareProtocolReservationStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.sequence = sequence
            self.weight = weight
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

        func canMoveTo(_ next: ManualCareProtocolReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualCareProtocolReservationStatus.granted
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

        func moveTo(_ next: ManualCareProtocolReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveValue() -> Double {
            return ((floorValue - weight) * 100).rounded() / 100
        }

        func copyValue() -> ManualCareProtocolReservation {
            return ManualCareProtocolReservation(
                code: code,
                label: label,
                name: name,
                reviewer: reviewer,
                floorValue: floorValue,
                sequence: sequence,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual care protocol reservation in status requested.
    static func newManualCareProtocolReservation(_ code: String, label: String) -> ManualCareProtocolReservation {
        return ManualCareProtocolReservation(
            code: code,
            label: label,
            name: "",
            reviewer: "",
            floorValue: 0.0,
            sequence: 0,
            weight: 0.0,
            status: ManualCareProtocolReservationStatus.requested
        )
    }
}
