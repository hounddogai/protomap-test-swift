import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan reservation is in its life cycle.
    enum AcuityPlanReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A acuity plan reservation. Its code is unique within a tenant.
    final class AcuityPlanReservation {
        var code: String
        var title: String
        var sequence: Int
        var version: Int
        var minimum: Double
        var region: String
        var status: AcuityPlanReservationStatus

        init(code: String, title: String, sequence: Int, version: Int, minimum: Double, region: String, status: AcuityPlanReservationStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.version = version
            self.minimum = minimum
            self.region = region
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

        func canMoveTo(_ next: AcuityPlanReservationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AcuityPlanReservationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedVolume() -> Double {
            return (Double(sequence) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanReservation {
            return AcuityPlanReservation(
                code: code,
                title: title,
                sequence: sequence,
                version: version,
                minimum: minimum,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a acuity plan reservation in status idle.
    static func newAcuityPlanReservation(_ code: String, title: String) -> AcuityPlanReservation {
        return AcuityPlanReservation(
            code: code,
            title: title,
            sequence: 0,
            version: 0,
            minimum: 0.0,
            region: "",
            status: AcuityPlanReservationStatus.idle
        )
    }
}
