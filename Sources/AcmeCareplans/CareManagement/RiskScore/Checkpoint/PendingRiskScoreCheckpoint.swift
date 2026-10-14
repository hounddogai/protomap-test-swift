import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending risk score checkpoint is in its life cycle.
    enum PendingRiskScoreCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending risk score checkpoint. Its code is unique within a tenant.
    final class PendingRiskScoreCheckpoint {
        var code: String
        var label: String
        var pinned: Bool
        var startsAt: Int
        var externalRef: String
        var revision: Int
        var segment: String
        var budget: Double
        var currency: String
        var status: PendingRiskScoreCheckpointStatus

        init(code: String, label: String, pinned: Bool, startsAt: Int, externalRef: String, revision: Int, segment: String, budget: Double, currency: String, status: PendingRiskScoreCheckpointStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.startsAt = startsAt
            self.externalRef = externalRef
            self.revision = revision
            self.segment = segment
            self.budget = budget
            self.currency = currency
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

        func canMoveTo(_ next: PendingRiskScoreCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingRiskScoreCheckpointStatus.ready || next == PendingRiskScoreCheckpointStatus.draining
            case .ready:
                return next == PendingRiskScoreCheckpointStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingRiskScoreCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending risk score checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("pending risk score checkpoint") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(revision) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingRiskScoreCheckpoint {
            return PendingRiskScoreCheckpoint(
                code: code,
                label: label,
                pinned: pinned,
                startsAt: startsAt,
                externalRef: externalRef,
                revision: revision,
                segment: segment,
                budget: budget,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending risk score checkpoint in status idle.
    static func newPendingRiskScoreCheckpoint(_ code: String, label: String) -> PendingRiskScoreCheckpoint {
        return PendingRiskScoreCheckpoint(
            code: code,
            label: label,
            pinned: false,
            startsAt: 0,
            externalRef: "",
            revision: 0,
            segment: "",
            budget: 0.0,
            currency: "",
            status: PendingRiskScoreCheckpointStatus.idle
        )
    }
}
