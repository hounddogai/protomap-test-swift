import AcmePlatform
import Foundation

extension Labs {
    /// Where a global specimen slot is in its life cycle.
    enum GlobalSpecimenSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global specimen slot. Its code is unique within a tenant.
    final class GlobalSpecimenSlot {
        var code: String
        var title: String
        var retries: Int
        var cost: Double
        var rate: Double
        var status: GlobalSpecimenSlotStatus

        init(code: String, title: String, retries: Int, cost: Double, rate: Double, status: GlobalSpecimenSlotStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.cost = cost
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalSpecimenSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalSpecimenSlotStatus.queued || next == GlobalSpecimenSlotStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == GlobalSpecimenSlotStatus.done || next == GlobalSpecimenSlotStatus.failed
            case .done:
                return next == GlobalSpecimenSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalSpecimenSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global specimen slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global specimen slot") \(code)"
        }

        func effectiveVolume() -> Double {
            return (cost * rate * 100).rounded() / 100
        }

        func copyValue() -> GlobalSpecimenSlot {
            return GlobalSpecimenSlot(
                code: code,
                title: title,
                retries: retries,
                cost: cost,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global specimen slot in status new.
    static func newGlobalSpecimenSlot(_ code: String, title: String) -> GlobalSpecimenSlot {
        return GlobalSpecimenSlot(
            code: code,
            title: title,
            retries: 0,
            cost: 0.0,
            rate: 0.0,
            status: GlobalSpecimenSlotStatus.new
        )
    }
}
