import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback denial template is in its life cycle.
    enum FallbackDenialTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback denial template. Its code is unique within a tenant.
    final class FallbackDenialTemplate {
        var code: String
        var name: String
        var updatedAt: Int
        var capacity: Int
        var diagnosisCode: String
        var channel: String
        var weight: Double
        var status: FallbackDenialTemplateStatus

        init(code: String, name: String, updatedAt: Int, capacity: Int, diagnosisCode: String, channel: String, weight: Double, status: FallbackDenialTemplateStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.diagnosisCode = diagnosisCode
            self.channel = channel
            self.weight = weight
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

        func canMoveTo(_ next: FallbackDenialTemplateStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackDenialTemplateStatus.completed || next == FallbackDenialTemplateStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackDenialTemplateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDenialTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback denial template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(updatedAt) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDenialTemplate {
            return FallbackDenialTemplate(
                code: code,
                name: name,
                updatedAt: updatedAt,
                capacity: capacity,
                diagnosisCode: diagnosisCode,
                channel: channel,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback denial template in status planned.
    static func newFallbackDenialTemplate(_ code: String, name: String) -> FallbackDenialTemplate {
        return FallbackDenialTemplate(
            code: code,
            name: name,
            updatedAt: 0,
            capacity: 0,
            diagnosisCode: "",
            channel: "",
            weight: 0.0,
            status: FallbackDenialTemplateStatus.planned
        )
    }
}
