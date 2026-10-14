import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered transfer bundle is in its life cycle.
    enum TieredTransferBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered transfer bundle. Its code is unique within a tenant.
    final class TieredTransferBundle {
        var code: String
        var label: String
        var sequence: Int
        var visible: Bool
        var locale: String
        var specialty: String
        var minimum: Double
        var status: TieredTransferBundleStatus

        init(code: String, label: String, sequence: Int, visible: Bool, locale: String, specialty: String, minimum: Double, status: TieredTransferBundleStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.visible = visible
            self.locale = locale
            self.specialty = specialty
            self.minimum = minimum
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

        func canMoveTo(_ next: TieredTransferBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredTransferBundleStatus.withdrawn
            case .approved:
                return next == TieredTransferBundleStatus.rejected || next == TieredTransferBundleStatus.withdrawn
            case .rejected:
                return next == TieredTransferBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredTransferBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered transfer bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netExposure() -> Double {
            return (minimum * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> TieredTransferBundle {
            return TieredTransferBundle(
                code: code,
                label: label,
                sequence: sequence,
                visible: visible,
                locale: locale,
                specialty: specialty,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a tiered transfer bundle in status proposed.
    static func newTieredTransferBundle(_ code: String, label: String) -> TieredTransferBundle {
        return TieredTransferBundle(
            code: code,
            label: label,
            sequence: 0,
            visible: false,
            locale: "",
            specialty: "",
            minimum: 0.0,
            status: TieredTransferBundleStatus.proposed
        )
    }
}
