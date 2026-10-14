import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool checkpoint is in its life cycle.
    enum FloatPoolCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A float pool checkpoint as the float pool team keeps it.
    final class FloatPoolCheckpoint {
        var code: String
        var label: String
        var allergy: String
        var ward: String
        var retries: Int
        var weight: Double
        var pinned: Bool
        var active: Bool
        var title: String
        var endsAt: Int
        var procedureCode: String
        var status: FloatPoolCheckpointStatus

        init(code: String, label: String, allergy: String, ward: String, retries: Int, weight: Double, pinned: Bool, active: Bool, title: String, endsAt: Int, procedureCode: String, status: FloatPoolCheckpointStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.ward = ward
            self.retries = retries
            self.weight = weight
            self.pinned = pinned
            self.active = active
            self.title = title
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FloatPoolCheckpointStatus.suspended || next == FloatPoolCheckpointStatus.closed
            case .active:
                return next == FloatPoolCheckpointStatus.suspended || next == FloatPoolCheckpointStatus.closed
            case .suspended:
                return next == FloatPoolCheckpointStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return ((weight + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolCheckpoint {
            return FloatPoolCheckpoint(
                code: code,
                label: label,
                allergy: allergy,
                ward: ward,
                retries: retries,
                weight: weight,
                pinned: pinned,
                active: active,
                title: title,
                endsAt: endsAt,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a float pool checkpoint in status draft.
    static func newFloatPoolCheckpoint(_ code: String, label: String) -> FloatPoolCheckpoint {
        return FloatPoolCheckpoint(
            code: code,
            label: label,
            allergy: "",
            ward: "",
            retries: 0,
            weight: 0.0,
            pinned: false,
            active: false,
            title: "",
            endsAt: 0,
            procedureCode: "",
            status: FloatPoolCheckpointStatus.draft
        )
    }
}
