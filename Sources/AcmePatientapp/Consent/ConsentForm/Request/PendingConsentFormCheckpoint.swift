import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending consent form checkpoint is in its life cycle.
    enum PendingConsentFormCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending consent form checkpoint. Its code is unique within a tenant.
    final class PendingConsentFormCheckpoint {
        var code: String
        var name: String
        var score: Double
        var facility: String
        var diagnosisCode: String
        var pinned: Bool
        var margin: Double
        var cost: Double
        var status: PendingConsentFormCheckpointStatus

        init(code: String, name: String, score: Double, facility: String, diagnosisCode: String, pinned: Bool, margin: Double, cost: Double, status: PendingConsentFormCheckpointStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.pinned = pinned
            self.margin = margin
            self.cost = cost
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

        func canMoveTo(_ next: PendingConsentFormCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingConsentFormCheckpointStatus.draining
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

        func moveTo(_ next: PendingConsentFormCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending consent form checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending consent form checkpoint") \(code)"
        }

        func netExposure() -> Double {
            return ((margin - score) * 100).rounded() / 100
        }

        func copyValue() -> PendingConsentFormCheckpoint {
            return PendingConsentFormCheckpoint(
                code: code,
                name: name,
                score: score,
                facility: facility,
                diagnosisCode: diagnosisCode,
                pinned: pinned,
                margin: margin,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending consent form checkpoint in status idle.
    static func newPendingConsentFormCheckpoint(_ code: String, name: String) -> PendingConsentFormCheckpoint {
        return PendingConsentFormCheckpoint(
            code: code,
            name: name,
            score: 0.0,
            facility: "",
            diagnosisCode: "",
            pinned: false,
            margin: 0.0,
            cost: 0.0,
            status: PendingConsentFormCheckpointStatus.idle
        )
    }
}
