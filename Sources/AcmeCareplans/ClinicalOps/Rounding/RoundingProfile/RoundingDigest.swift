import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding digest is in its life cycle.
    enum RoundingDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rounding digest, with what the planners need to act on it.
    final class RoundingDigest {
        var code: String
        var name: String
        var sequence: Int
        var threshold: Double
        var clinicianID: String
        var active: Bool
        var updatedAt: Int
        var acuity: Int
        var priority: Int
        var region: String
        var maximum: Double
        var status: RoundingDigestStatus

        init(code: String, name: String, sequence: Int, threshold: Double, clinicianID: String, active: Bool, updatedAt: Int, acuity: Int, priority: Int, region: String, maximum: Double, status: RoundingDigestStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.threshold = threshold
            self.clinicianID = clinicianID
            self.active = active
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.priority = priority
            self.region = region
            self.maximum = maximum
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

        func canMoveTo(_ next: RoundingDigestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RoundingDigestStatus.inProgress || next == RoundingDigestStatus.completed
            case .inProgress:
                return next == RoundingDigestStatus.completed || next == RoundingDigestStatus.cancelled
            case .completed:
                return next == RoundingDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((threshold + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingDigest {
            return RoundingDigest(
                code: code,
                name: name,
                sequence: sequence,
                threshold: threshold,
                clinicianID: clinicianID,
                active: active,
                updatedAt: updatedAt,
                acuity: acuity,
                priority: priority,
                region: region,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rounding digest in status planned.
    static func newRoundingDigest(_ code: String, name: String) -> RoundingDigest {
        return RoundingDigest(
            code: code,
            name: name,
            sequence: 0,
            threshold: 0.0,
            clinicianID: "",
            active: false,
            updatedAt: 0,
            acuity: 0,
            priority: 0,
            region: "",
            maximum: 0.0,
            status: RoundingDigestStatus.planned
        )
    }
}
