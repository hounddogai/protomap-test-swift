import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime reservation is in its life cycle.
    enum OvertimeReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A overtime reservation. Its code is unique within a tenant.
    final class OvertimeReservation {
        var code: String
        var title: String
        var clinicianID: String
        var threshold: Double
        var dosageMg: Double
        var source: String
        var unit: String
        var region: String
        var status: OvertimeReservationStatus

        init(code: String, title: String, clinicianID: String, threshold: Double, dosageMg: Double, source: String, unit: String, region: String, status: OvertimeReservationStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.source = source
            self.unit = unit
            self.region = region
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

        func canMoveTo(_ next: OvertimeReservationStatus) -> Bool {
            switch status {
            case .planned:
                return next == OvertimeReservationStatus.scheduled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == OvertimeReservationStatus.completed
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

        func moveTo(_ next: OvertimeReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return ((dosageMg - threshold) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeReservation {
            return OvertimeReservation(
                code: code,
                title: title,
                clinicianID: clinicianID,
                threshold: threshold,
                dosageMg: dosageMg,
                source: source,
                unit: unit,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a overtime reservation in status planned.
    static func newOvertimeReservation(_ code: String, title: String) -> OvertimeReservation {
        return OvertimeReservation(
            code: code,
            title: title,
            clinicianID: "",
            threshold: 0.0,
            dosageMg: 0.0,
            source: "",
            unit: "",
            region: "",
            status: OvertimeReservationStatus.planned
        )
    }
}
