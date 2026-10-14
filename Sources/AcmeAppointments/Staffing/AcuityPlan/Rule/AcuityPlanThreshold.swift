import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan threshold is in its life cycle.
    enum AcuityPlanThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A acuity plan threshold. Its code is unique within a tenant.
    final class AcuityPlanThreshold {
        var code: String
        var name: String
        var reviewer: String
        var checksum: String
        var segment: String
        var label: String
        var durationMinutes: Int
        var batchSize: Int
        var attempts: Int
        var status: AcuityPlanThresholdStatus

        init(code: String, name: String, reviewer: String, checksum: String, segment: String, label: String, durationMinutes: Int, batchSize: Int, attempts: Int, status: AcuityPlanThresholdStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.checksum = checksum
            self.segment = segment
            self.label = label
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.attempts = attempts
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

        func canMoveTo(_ next: AcuityPlanThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == AcuityPlanThresholdStatus.revoked || next == AcuityPlanThresholdStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AcuityPlanThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return (Double(attempts) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanThreshold {
            return AcuityPlanThreshold(
                code: code,
                name: name,
                reviewer: reviewer,
                checksum: checksum,
                segment: segment,
                label: label,
                durationMinutes: durationMinutes,
                batchSize: batchSize,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a acuity plan threshold in status requested.
    static func newAcuityPlanThreshold(_ code: String, name: String) -> AcuityPlanThreshold {
        return AcuityPlanThreshold(
            code: code,
            name: name,
            reviewer: "",
            checksum: "",
            segment: "",
            label: "",
            durationMinutes: 0,
            batchSize: 0,
            attempts: 0,
            status: AcuityPlanThresholdStatus.requested
        )
    }
}
