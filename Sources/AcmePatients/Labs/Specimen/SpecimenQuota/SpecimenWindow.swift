import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen window is in its life cycle.
    enum SpecimenWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A specimen window. Its code is unique within a tenant.
    final class SpecimenWindow {
        var code: String
        var title: String
        var checksum: String
        var ratio: Double
        var quantity: Int
        var amount: Double
        var status: SpecimenWindowStatus

        init(code: String, title: String, checksum: String, ratio: Double, quantity: Int, amount: Double, status: SpecimenWindowStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.ratio = ratio
            self.quantity = quantity
            self.amount = amount
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

        func canMoveTo(_ next: SpecimenWindowStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SpecimenWindowStatus.rejected || next == SpecimenWindowStatus.withdrawn
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

        func moveTo(_ next: SpecimenWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedValue() -> Double {
            return ((ratio + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenWindow {
            return SpecimenWindow(
                code: code,
                title: title,
                checksum: checksum,
                ratio: ratio,
                quantity: quantity,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a specimen window in status proposed.
    static func newSpecimenWindow(_ code: String, title: String) -> SpecimenWindow {
        return SpecimenWindow(
            code: code,
            title: title,
            checksum: "",
            ratio: 0.0,
            quantity: 0,
            amount: 0.0,
            status: SpecimenWindowStatus.proposed
        )
    }
}
