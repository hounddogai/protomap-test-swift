import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier variance is in its life cycle.
    enum CourierVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A courier variance as the courier team keeps it.
    final class CourierVariance {
        var code: String
        var label: String
        var threshold: Double
        var visible: Bool
        var visitMinutes: Int
        var createdAt: Int
        var updatedAt: Int
        var ceiling: Double
        var active: Bool
        var externalRef: String
        var allergy: String
        var status: CourierVarianceStatus

        init(code: String, label: String, threshold: Double, visible: Bool, visitMinutes: Int, createdAt: Int, updatedAt: Int, ceiling: Double, active: Bool, externalRef: String, allergy: String, status: CourierVarianceStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.visible = visible
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.active = active
            self.externalRef = externalRef
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

        func canMoveTo(_ next: CourierVarianceStatus) -> Bool {
            switch status {
            case .requested:
                return next == CourierVarianceStatus.granted || next == CourierVarianceStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CourierVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return (threshold * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CourierVariance {
            return CourierVariance(
                code: code,
                label: label,
                threshold: threshold,
                visible: visible,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                ceiling: ceiling,
                active: active,
                externalRef: externalRef,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a courier variance in status requested.
    static func newCourierVariance(_ code: String, label: String) -> CourierVariance {
        return CourierVariance(
            code: code,
            label: label,
            threshold: 0.0,
            visible: false,
            visitMinutes: 0,
            createdAt: 0,
            updatedAt: 0,
            ceiling: 0.0,
            active: false,
            externalRef: "",
            allergy: "",
            status: CourierVarianceStatus.requested
        )
    }
}
