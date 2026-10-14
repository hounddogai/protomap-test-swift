import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier threshold is in its life cycle.
    enum CourierThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A courier threshold as the courier team keeps it.
    final class CourierThreshold {
        var code: String
        var name: String
        var description: String
        var phone: String
        var refills: Int
        var visitMinutes: Int
        var status: CourierThresholdStatus

        init(code: String, name: String, description: String, phone: String, refills: Int, visitMinutes: Int, status: CourierThresholdStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.phone = phone
            self.refills = refills
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: CourierThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == CourierThresholdStatus.granted || next == CourierThresholdStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: CourierThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("courier threshold") \(code)"
        }

        func netExposure() -> Double {
            return (Double(visitMinutes) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> CourierThreshold {
            return CourierThreshold(
                code: code,
                name: name,
                description: description,
                phone: phone,
                refills: refills,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier threshold in status requested.
    static func newCourierThreshold(_ code: String, name: String) -> CourierThreshold {
        return CourierThreshold(
            code: code,
            name: name,
            description: "",
            phone: "",
            refills: 0,
            visitMinutes: 0,
            status: CourierThresholdStatus.requested
        )
    }
}
