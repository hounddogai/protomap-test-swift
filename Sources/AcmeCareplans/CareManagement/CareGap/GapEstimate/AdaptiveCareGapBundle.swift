import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive care gap bundle is in its life cycle.
    enum AdaptiveCareGapBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive care gap bundle. Its code is unique within a tenant.
    final class AdaptiveCareGapBundle {
        var code: String
        var label: String
        var notes: String
        var graceDays: Int
        var active: Bool
        var limit: Int
        var category: String
        var expiresAt: Int
        var updatedAt: Int
        var status: AdaptiveCareGapBundleStatus

        init(code: String, label: String, notes: String, graceDays: Int, active: Bool, limit: Int, category: String, expiresAt: Int, updatedAt: Int, status: AdaptiveCareGapBundleStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.graceDays = graceDays
            self.active = active
            self.limit = limit
            self.category = category
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: AdaptiveCareGapBundleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveCareGapBundleStatus.rejected || next == AdaptiveCareGapBundleStatus.withdrawn
            case .rejected:
                return next == AdaptiveCareGapBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCareGapBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care gap bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return ((Double(graceDays) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCareGapBundle {
            return AdaptiveCareGapBundle(
                code: code,
                label: label,
                notes: notes,
                graceDays: graceDays,
                active: active,
                limit: limit,
                category: category,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive care gap bundle in status proposed.
    static func newAdaptiveCareGapBundle(_ code: String, label: String) -> AdaptiveCareGapBundle {
        return AdaptiveCareGapBundle(
            code: code,
            label: label,
            notes: "",
            graceDays: 0,
            active: false,
            limit: 0,
            category: "",
            expiresAt: 0,
            updatedAt: 0,
            status: AdaptiveCareGapBundleStatus.proposed
        )
    }
}
