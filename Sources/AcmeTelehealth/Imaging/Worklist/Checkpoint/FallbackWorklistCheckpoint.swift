import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback worklist checkpoint is in its life cycle.
    enum FallbackWorklistCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback worklist checkpoint as the worklist team keeps it.
    final class FallbackWorklistCheckpoint {
        var code: String
        var label: String
        var ratio: Double
        var limit: Int
        var ward: String
        var expiresAt: Int
        var windowDays: Int
        var weight: Double
        var unit: String
        var summary: String
        var reviewer: String
        var status: FallbackWorklistCheckpointStatus

        init(code: String, label: String, ratio: Double, limit: Int, ward: String, expiresAt: Int, windowDays: Int, weight: Double, unit: String, summary: String, reviewer: String, status: FallbackWorklistCheckpointStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.limit = limit
            self.ward = ward
            self.expiresAt = expiresAt
            self.windowDays = windowDays
            self.weight = weight
            self.unit = unit
            self.summary = summary
            self.reviewer = reviewer
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

        func canMoveTo(_ next: FallbackWorklistCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FallbackWorklistCheckpointStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackWorklistCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback worklist checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveValue() -> Double {
            return (ratio * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> FallbackWorklistCheckpoint {
            return FallbackWorklistCheckpoint(
                code: code,
                label: label,
                ratio: ratio,
                limit: limit,
                ward: ward,
                expiresAt: expiresAt,
                windowDays: windowDays,
                weight: weight,
                unit: unit,
                summary: summary,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback worklist checkpoint in status proposed.
    static func newFallbackWorklistCheckpoint(_ code: String, label: String) -> FallbackWorklistCheckpoint {
        return FallbackWorklistCheckpoint(
            code: code,
            label: label,
            ratio: 0.0,
            limit: 0,
            ward: "",
            expiresAt: 0,
            windowDays: 0,
            weight: 0.0,
            unit: "",
            summary: "",
            reviewer: "",
            status: FallbackWorklistCheckpointStatus.proposed
        )
    }
}
