import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient charge tier is in its life cycle.
    enum LenientChargeTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient charge tier. Its code is unique within a tenant.
    final class LenientChargeTier {
        var code: String
        var label: String
        var version: Int
        var externalRef: String
        var encounterID: String
        var quantity: Int
        var active: Bool
        var updatedAt: Int
        var ceiling: Double
        var revision: Int
        var status: LenientChargeTierStatus

        init(code: String, label: String, version: Int, externalRef: String, encounterID: String, quantity: Int, active: Bool, updatedAt: Int, ceiling: Double, revision: Int, status: LenientChargeTierStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.externalRef = externalRef
            self.encounterID = encounterID
            self.quantity = quantity
            self.active = active
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientChargeTierStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientChargeTierStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientChargeTierStatus.suspended
            case .suspended:
                return next == LenientChargeTierStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientChargeTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient charge tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return (Double(quantity) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> LenientChargeTier {
            return LenientChargeTier(
                code: code,
                label: label,
                version: version,
                externalRef: externalRef,
                encounterID: encounterID,
                quantity: quantity,
                active: active,
                updatedAt: updatedAt,
                ceiling: ceiling,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient charge tier in status draft.
    static func newLenientChargeTier(_ code: String, label: String) -> LenientChargeTier {
        return LenientChargeTier(
            code: code,
            label: label,
            version: 0,
            externalRef: "",
            encounterID: "",
            quantity: 0,
            active: false,
            updatedAt: 0,
            ceiling: 0.0,
            revision: 0,
            status: LenientChargeTierStatus.draft
        )
    }
}
