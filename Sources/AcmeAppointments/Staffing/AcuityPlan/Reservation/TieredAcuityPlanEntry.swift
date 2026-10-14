import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered acuity plan entry is in its life cycle.
    enum TieredAcuityPlanEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered acuity plan entry. Its code is unique within a tenant.
    final class TieredAcuityPlanEntry {
        var code: String
        var name: String
        var graceDays: Int
        var acuity: Int
        var minimum: Double
        var status: TieredAcuityPlanEntryStatus

        init(code: String, name: String, graceDays: Int, acuity: Int, minimum: Double, status: TieredAcuityPlanEntryStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.acuity = acuity
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredAcuityPlanEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredAcuityPlanEntryStatus.warming || next == TieredAcuityPlanEntryStatus.ready
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: TieredAcuityPlanEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered acuity plan entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(acuity) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> TieredAcuityPlanEntry {
            return TieredAcuityPlanEntry(
                code: code,
                name: name,
                graceDays: graceDays,
                acuity: acuity,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered acuity plan entry in status idle.
    static func newTieredAcuityPlanEntry(_ code: String, name: String) -> TieredAcuityPlanEntry {
        return TieredAcuityPlanEntry(
            code: code,
            name: name,
            graceDays: 0,
            acuity: 0,
            minimum: 0.0,
            status: TieredAcuityPlanEntryStatus.idle
        )
    }
}
