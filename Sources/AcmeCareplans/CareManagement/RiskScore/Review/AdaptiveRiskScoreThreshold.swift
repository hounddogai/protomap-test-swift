import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive risk score threshold is in its life cycle.
    enum AdaptiveRiskScoreThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive risk score threshold, with what the planners need to act on it.
    final class AdaptiveRiskScoreThreshold {
        var code: String
        var title: String
        var durationMinutes: Int
        var ward: String
        var revision: Int
        var status: AdaptiveRiskScoreThresholdStatus

        init(code: String, title: String, durationMinutes: Int, ward: String, revision: Int, status: AdaptiveRiskScoreThresholdStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.revision = revision
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

        func canMoveTo(_ next: AdaptiveRiskScoreThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveRiskScoreThresholdStatus.granted || next == AdaptiveRiskScoreThresholdStatus.revoked
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

        func moveTo(_ next: AdaptiveRiskScoreThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive risk score threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netLoad() -> Double {
            return (Double(durationMinutes) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRiskScoreThreshold {
            return AdaptiveRiskScoreThreshold(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                ward: ward,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive risk score threshold in status requested.
    static func newAdaptiveRiskScoreThreshold(_ code: String, title: String) -> AdaptiveRiskScoreThreshold {
        return AdaptiveRiskScoreThreshold(
            code: code,
            title: title,
            durationMinutes: 0,
            ward: "",
            revision: 0,
            status: AdaptiveRiskScoreThresholdStatus.requested
        )
    }
}
