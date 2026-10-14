import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift checkpoint is in its life cycle.
    enum ShiftCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A shift checkpoint. Its code is unique within a tenant.
    final class ShiftCheckpoint {
        var code: String
        var label: String
        var segment: String
        var endsAt: Int
        var description: String
        var margin: Double
        var threshold: Double
        var currency: String
        var pinned: Bool
        var status: ShiftCheckpointStatus

        init(code: String, label: String, segment: String, endsAt: Int, description: String, margin: Double, threshold: Double, currency: String, pinned: Bool, status: ShiftCheckpointStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.endsAt = endsAt
            self.description = description
            self.margin = margin
            self.threshold = threshold
            self.currency = currency
            self.pinned = pinned
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

        func canMoveTo(_ next: ShiftCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                return next == ShiftCheckpointStatus.closed
            case .pending:
                return next == ShiftCheckpointStatus.suspended || next == ShiftCheckpointStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ShiftCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return (threshold * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> ShiftCheckpoint {
            return ShiftCheckpoint(
                code: code,
                label: label,
                segment: segment,
                endsAt: endsAt,
                description: description,
                margin: margin,
                threshold: threshold,
                currency: currency,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a shift checkpoint in status draft.
    static func newShiftCheckpoint(_ code: String, label: String) -> ShiftCheckpoint {
        return ShiftCheckpoint(
            code: code,
            label: label,
            segment: "",
            endsAt: 0,
            description: "",
            margin: 0.0,
            threshold: 0.0,
            currency: "",
            pinned: false,
            status: ShiftCheckpointStatus.draft
        )
    }
}
