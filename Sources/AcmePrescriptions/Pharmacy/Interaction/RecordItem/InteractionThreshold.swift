import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction threshold is in its life cycle.
    enum InteractionThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A interaction threshold. Its code is unique within a tenant.
    final class InteractionThreshold {
        var code: String
        var name: String
        var rate: Double
        var archived: Bool
        var maximum: Double
        var diagnosisCode: String
        var status: InteractionThresholdStatus

        init(code: String, name: String, rate: Double, archived: Bool, maximum: Double, diagnosisCode: String, status: InteractionThresholdStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.archived = archived
            self.maximum = maximum
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: InteractionThresholdStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == InteractionThresholdStatus.revoked || next == InteractionThresholdStatus.expired
            case .revoked:
                return next == InteractionThresholdStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("interaction threshold") \(code)"
        }

        func adjustedTotal() -> Double {
            return (maximum * rate * 100).rounded() / 100
        }

        func copyValue() -> InteractionThreshold {
            return InteractionThreshold(
                code: code,
                name: name,
                rate: rate,
                archived: archived,
                maximum: maximum,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction threshold in status requested.
    static func newInteractionThreshold(_ code: String, name: String) -> InteractionThreshold {
        return InteractionThreshold(
            code: code,
            name: name,
            rate: 0.0,
            archived: false,
            maximum: 0.0,
            diagnosisCode: "",
            status: InteractionThresholdStatus.requested
        )
    }
}
