import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality audit is in its life cycle.
    enum ModalityAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One modality audit, with what the planners need to act on it.
    final class ModalityAudit {
        var code: String
        var title: String
        var maximum: Double
        var limit: Int
        var timezone: String
        var dosageMg: Double
        var floorValue: Double
        var pinned: Bool
        var facility: String
        var ward: String
        var status: ModalityAuditStatus

        init(code: String, title: String, maximum: Double, limit: Int, timezone: String, dosageMg: Double, floorValue: Double, pinned: Bool, facility: String, ward: String, status: ModalityAuditStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.limit = limit
            self.timezone = timezone
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.pinned = pinned
            self.facility = facility
            self.ward = ward
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

        func canMoveTo(_ next: ModalityAuditStatus) -> Bool {
            switch status {
            case .idle:
                return next == ModalityAuditStatus.ready || next == ModalityAuditStatus.stopped
            case .warming:
                return next == ModalityAuditStatus.ready || next == ModalityAuditStatus.stopped
            case .ready:
                return next == ModalityAuditStatus.draining
            case .draining:
                return next == ModalityAuditStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return (Double(limit) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ModalityAudit {
            return ModalityAudit(
                code: code,
                title: title,
                maximum: maximum,
                limit: limit,
                timezone: timezone,
                dosageMg: dosageMg,
                floorValue: floorValue,
                pinned: pinned,
                facility: facility,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a modality audit in status idle.
    static func newModalityAudit(_ code: String, title: String) -> ModalityAudit {
        return ModalityAudit(
            code: code,
            title: title,
            maximum: 0.0,
            limit: 0,
            timezone: "",
            dosageMg: 0.0,
            floorValue: 0.0,
            pinned: false,
            facility: "",
            ward: "",
            status: ModalityAuditStatus.idle
        )
    }
}
