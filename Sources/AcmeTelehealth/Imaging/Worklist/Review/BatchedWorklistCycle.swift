import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched worklist cycle is in its life cycle.
    enum BatchedWorklistCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched worklist cycle. Its code is unique within a tenant.
    final class BatchedWorklistCycle {
        var code: String
        var label: String
        var summary: String
        var facility: String
        var threshold: Double
        var endsAt: Int
        var allergy: String
        var status: BatchedWorklistCycleStatus

        init(code: String, label: String, summary: String, facility: String, threshold: Double, endsAt: Int, allergy: String, status: BatchedWorklistCycleStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.facility = facility
            self.threshold = threshold
            self.endsAt = endsAt
            self.allergy = allergy
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

        func canMoveTo(_ next: BatchedWorklistCycleStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedWorklistCycleStatus.granted || next == BatchedWorklistCycleStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == BatchedWorklistCycleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedWorklistCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched worklist cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("batched worklist cycle") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> BatchedWorklistCycle {
            return BatchedWorklistCycle(
                code: code,
                label: label,
                summary: summary,
                facility: facility,
                threshold: threshold,
                endsAt: endsAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched worklist cycle in status requested.
    static func newBatchedWorklistCycle(_ code: String, label: String) -> BatchedWorklistCycle {
        return BatchedWorklistCycle(
            code: code,
            label: label,
            summary: "",
            facility: "",
            threshold: 0.0,
            endsAt: 0,
            allergy: "",
            status: BatchedWorklistCycleStatus.requested
        )
    }
}
