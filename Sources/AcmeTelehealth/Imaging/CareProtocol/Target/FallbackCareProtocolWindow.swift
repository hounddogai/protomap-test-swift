import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback care protocol window is in its life cycle.
    enum FallbackCareProtocolWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback care protocol window. Its code is unique within a tenant.
    final class FallbackCareProtocolWindow {
        var code: String
        var title: String
        var discount: Double
        var dosageMg: Double
        var createdAt: Int
        var copay: Double
        var active: Bool
        var notes: String
        var bed: String
        var specialty: String
        var margin: Double
        var status: FallbackCareProtocolWindowStatus

        init(code: String, title: String, discount: Double, dosageMg: Double, createdAt: Int, copay: Double, active: Bool, notes: String, bed: String, specialty: String, margin: Double, status: FallbackCareProtocolWindowStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.copay = copay
            self.active = active
            self.notes = notes
            self.bed = bed
            self.specialty = specialty
            self.margin = margin
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

        func canMoveTo(_ next: FallbackCareProtocolWindowStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackCareProtocolWindowStatus.granted || next == FallbackCareProtocolWindowStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackCareProtocolWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCareProtocolWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedValue() -> Double {
            return (copay * discount * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareProtocolWindow {
            return FallbackCareProtocolWindow(
                code: code,
                title: title,
                discount: discount,
                dosageMg: dosageMg,
                createdAt: createdAt,
                copay: copay,
                active: active,
                notes: notes,
                bed: bed,
                specialty: specialty,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback care protocol window in status requested.
    static func newFallbackCareProtocolWindow(_ code: String, title: String) -> FallbackCareProtocolWindow {
        return FallbackCareProtocolWindow(
            code: code,
            title: title,
            discount: 0.0,
            dosageMg: 0.0,
            createdAt: 0,
            copay: 0.0,
            active: false,
            notes: "",
            bed: "",
            specialty: "",
            margin: 0.0,
            status: FallbackCareProtocolWindowStatus.requested
        )
    }
}
