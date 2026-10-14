import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global formulary entry is in its life cycle.
    enum GlobalFormularyEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global formulary entry. Its code is unique within a tenant.
    final class GlobalFormularyEntry {
        var code: String
        var name: String
        var discount: Double
        var revision: Int
        var payer: String
        var rate: Double
        var updatedAt: Int
        var status: GlobalFormularyEntryStatus

        init(code: String, name: String, discount: Double, revision: Int, payer: String, rate: Double, updatedAt: Int, status: GlobalFormularyEntryStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.revision = revision
            self.payer = payer
            self.rate = rate
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: GlobalFormularyEntryStatus) -> Bool {
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
                switch next {
                case .revoked:
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

        func moveTo(_ next: GlobalFormularyEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global formulary entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("global formulary entry") \(code)"
        }

        func netVolume() -> Double {
            return ((rate - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFormularyEntry {
            return GlobalFormularyEntry(
                code: code,
                name: name,
                discount: discount,
                revision: revision,
                payer: payer,
                rate: rate,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global formulary entry in status requested.
    static func newGlobalFormularyEntry(_ code: String, name: String) -> GlobalFormularyEntry {
        return GlobalFormularyEntry(
            code: code,
            name: name,
            discount: 0.0,
            revision: 0,
            payer: "",
            rate: 0.0,
            updatedAt: 0,
            status: GlobalFormularyEntryStatus.requested
        )
    }
}
