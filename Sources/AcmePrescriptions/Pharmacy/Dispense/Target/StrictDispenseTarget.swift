import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict dispense target is in its life cycle.
    enum StrictDispenseTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict dispense target as the dispense team keeps it.
    final class StrictDispenseTarget {
        var code: String
        var label: String
        var updatedAt: Int
        var active: Bool
        var phone: String
        var version: Int
        var locale: String
        var status: StrictDispenseTargetStatus

        init(code: String, label: String, updatedAt: Int, active: Bool, phone: String, version: Int, locale: String, status: StrictDispenseTargetStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.active = active
            self.phone = phone
            self.version = version
            self.locale = locale
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

        func canMoveTo(_ next: StrictDispenseTargetStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictDispenseTargetStatus.expired
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

        func moveTo(_ next: StrictDispenseTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict dispense target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (Double(updatedAt) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> StrictDispenseTarget {
            return StrictDispenseTarget(
                code: code,
                label: label,
                updatedAt: updatedAt,
                active: active,
                phone: phone,
                version: version,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict dispense target in status requested.
    static func newStrictDispenseTarget(_ code: String, label: String) -> StrictDispenseTarget {
        return StrictDispenseTarget(
            code: code,
            label: label,
            updatedAt: 0,
            active: false,
            phone: "",
            version: 0,
            locale: "",
            status: StrictDispenseTargetStatus.requested
        )
    }
}
