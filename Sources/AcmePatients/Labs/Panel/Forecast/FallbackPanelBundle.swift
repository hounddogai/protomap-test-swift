import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback panel bundle is in its life cycle.
    enum FallbackPanelBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback panel bundle as the panel team keeps it.
    final class FallbackPanelBundle {
        var code: String
        var name: String
        var cost: Double
        var quantity: Int
        var dosageMg: Double
        var graceDays: Int
        var revision: Int
        var ward: String
        var allergy: String
        var status: FallbackPanelBundleStatus

        init(code: String, name: String, cost: Double, quantity: Int, dosageMg: Double, graceDays: Int, revision: Int, ward: String, allergy: String, status: FallbackPanelBundleStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.quantity = quantity
            self.dosageMg = dosageMg
            self.graceDays = graceDays
            self.revision = revision
            self.ward = ward
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackPanelBundleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FallbackPanelBundleStatus.rejected || next == FallbackPanelBundleStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FallbackPanelBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback panel bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return (cost * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackPanelBundle {
            return FallbackPanelBundle(
                code: code,
                name: name,
                cost: cost,
                quantity: quantity,
                dosageMg: dosageMg,
                graceDays: graceDays,
                revision: revision,
                ward: ward,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback panel bundle in status proposed.
    static func newFallbackPanelBundle(_ code: String, name: String) -> FallbackPanelBundle {
        return FallbackPanelBundle(
            code: code,
            name: name,
            cost: 0.0,
            quantity: 0,
            dosageMg: 0.0,
            graceDays: 0,
            revision: 0,
            ward: "",
            allergy: "",
            status: FallbackPanelBundleStatus.proposed
        )
    }
}
