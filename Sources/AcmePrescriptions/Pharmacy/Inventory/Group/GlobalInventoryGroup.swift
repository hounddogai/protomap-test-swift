import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global inventory group is in its life cycle.
    enum GlobalInventoryGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global inventory group. Its code is unique within a tenant.
    final class GlobalInventoryGroup {
        var code: String
        var title: String
        var visitMinutes: Int
        var dosageMg: Double
        var updatedAt: Int
        var pinned: Bool
        var allergy: String
        var status: GlobalInventoryGroupStatus

        init(code: String, title: String, visitMinutes: Int, dosageMg: Double, updatedAt: Int, pinned: Bool, allergy: String, status: GlobalInventoryGroupStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
            self.updatedAt = updatedAt
            self.pinned = pinned
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalInventoryGroupStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalInventoryGroupStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == GlobalInventoryGroupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalInventoryGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global inventory group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((Double(visitMinutes) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> GlobalInventoryGroup {
            return GlobalInventoryGroup(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                updatedAt: updatedAt,
                pinned: pinned,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global inventory group in status created.
    static func newGlobalInventoryGroup(_ code: String, title: String) -> GlobalInventoryGroup {
        return GlobalInventoryGroup(
            code: code,
            title: title,
            visitMinutes: 0,
            dosageMg: 0.0,
            updatedAt: 0,
            pinned: false,
            allergy: "",
            status: GlobalInventoryGroupStatus.created
        )
    }
}
