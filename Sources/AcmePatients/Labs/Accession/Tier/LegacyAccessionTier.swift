import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy accession tier is in its life cycle.
    enum LegacyAccessionTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy accession tier as the accession team keeps it.
    final class LegacyAccessionTier {
        var code: String
        var label: String
        var title: String
        var segment: String
        var visible: Bool
        var procedureCode: String
        var quantity: Int
        var status: LegacyAccessionTierStatus

        init(code: String, label: String, title: String, segment: String, visible: Bool, procedureCode: String, quantity: Int, status: LegacyAccessionTierStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.segment = segment
            self.visible = visible
            self.procedureCode = procedureCode
            self.quantity = quantity
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

        func canMoveTo(_ next: LegacyAccessionTierStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyAccessionTierStatus.rejected
            case .approved:
                return next == LegacyAccessionTierStatus.rejected || next == LegacyAccessionTierStatus.withdrawn
            case .rejected:
                return next == LegacyAccessionTierStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAccessionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy accession tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> LegacyAccessionTier {
            return LegacyAccessionTier(
                code: code,
                label: label,
                title: title,
                segment: segment,
                visible: visible,
                procedureCode: procedureCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy accession tier in status proposed.
    static func newLegacyAccessionTier(_ code: String, label: String) -> LegacyAccessionTier {
        return LegacyAccessionTier(
            code: code,
            label: label,
            title: "",
            segment: "",
            visible: false,
            procedureCode: "",
            quantity: 0,
            status: LegacyAccessionTierStatus.proposed
        )
    }
}
