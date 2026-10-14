import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback follow up baseline is in its life cycle.
    enum FallbackFollowUpBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One fallback follow up baseline, with what the planners need to act on it.
    final class FallbackFollowUpBaseline {
        var code: String
        var label: String
        var name: String
        var batchSize: Int
        var capacity: Int
        var retries: Int
        var createdAt: Int
        var ward: String
        var status: FallbackFollowUpBaselineStatus

        init(code: String, label: String, name: String, batchSize: Int, capacity: Int, retries: Int, createdAt: Int, ward: String, status: FallbackFollowUpBaselineStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.batchSize = batchSize
            self.capacity = capacity
            self.retries = retries
            self.createdAt = createdAt
            self.ward = ward
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

        func canMoveTo(_ next: FallbackFollowUpBaselineStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FallbackFollowUpBaselineStatus.cancelled
            case .completed:
                return next == FallbackFollowUpBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackFollowUpBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback follow up baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(createdAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFollowUpBaseline {
            return FallbackFollowUpBaseline(
                code: code,
                label: label,
                name: name,
                batchSize: batchSize,
                capacity: capacity,
                retries: retries,
                createdAt: createdAt,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback follow up baseline in status planned.
    static func newFallbackFollowUpBaseline(_ code: String, label: String) -> FallbackFollowUpBaseline {
        return FallbackFollowUpBaseline(
            code: code,
            label: label,
            name: "",
            batchSize: 0,
            capacity: 0,
            retries: 0,
            createdAt: 0,
            ward: "",
            status: FallbackFollowUpBaselineStatus.planned
        )
    }
}
