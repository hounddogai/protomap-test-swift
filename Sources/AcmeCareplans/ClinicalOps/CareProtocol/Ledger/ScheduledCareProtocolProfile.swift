import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled care protocol profile is in its life cycle.
    enum ScheduledCareProtocolProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled care protocol profile. Its code is unique within a tenant.
    final class ScheduledCareProtocolProfile {
        var code: String
        var name: String
        var rate: Double
        var diagnosisCode: String
        var region: String
        var status: ScheduledCareProtocolProfileStatus

        init(code: String, name: String, rate: Double, diagnosisCode: String, region: String, status: ScheduledCareProtocolProfileStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.diagnosisCode = diagnosisCode
            self.region = region
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

        func canMoveTo(_ next: ScheduledCareProtocolProfileStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
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
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ScheduledCareProtocolProfileStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareProtocolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled care protocol profile") \(code)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> ScheduledCareProtocolProfile {
            return ScheduledCareProtocolProfile(
                code: code,
                name: name,
                rate: rate,
                diagnosisCode: diagnosisCode,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled care protocol profile in status planned.
    static func newScheduledCareProtocolProfile(_ code: String, name: String) -> ScheduledCareProtocolProfile {
        return ScheduledCareProtocolProfile(
            code: code,
            name: name,
            rate: 0.0,
            diagnosisCode: "",
            region: "",
            status: ScheduledCareProtocolProfileStatus.planned
        )
    }
}
