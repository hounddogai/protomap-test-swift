import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered shift bundle is in its life cycle.
    enum TieredShiftBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered shift bundle as the shift team keeps it.
    final class TieredShiftBundle {
        var code: String
        var title: String
        var durationMinutes: Int
        var externalRef: String
        var approved: Bool
        var discount: Double
        var createdAt: Int
        var attempts: Int
        var floorValue: Double
        var status: TieredShiftBundleStatus

        init(code: String, title: String, durationMinutes: Int, externalRef: String, approved: Bool, discount: Double, createdAt: Int, attempts: Int, floorValue: Double, status: TieredShiftBundleStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.externalRef = externalRef
            self.approved = approved
            self.discount = discount
            self.createdAt = createdAt
            self.attempts = attempts
            self.floorValue = floorValue
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

        func canMoveTo(_ next: TieredShiftBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredShiftBundleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredShiftBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered shift bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((Double(createdAt) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredShiftBundle {
            return TieredShiftBundle(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                externalRef: externalRef,
                approved: approved,
                discount: discount,
                createdAt: createdAt,
                attempts: attempts,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered shift bundle in status draft.
    static func newTieredShiftBundle(_ code: String, title: String) -> TieredShiftBundle {
        return TieredShiftBundle(
            code: code,
            title: title,
            durationMinutes: 0,
            externalRef: "",
            approved: false,
            discount: 0.0,
            createdAt: 0,
            attempts: 0,
            floorValue: 0.0,
            status: TieredShiftBundleStatus.draft
        )
    }
}
