import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot reservation is in its life cycle.
    enum SlotReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a slot reservation and its current status.
    final class SlotReservation {
        var code: String
        var title: String
        var category: String
        var name: String
        var windowDays: Int
        var minimum: Double
        var active: Bool
        var cost: Double
        var checksum: String
        var status: SlotReservationStatus

        init(code: String, title: String, category: String, name: String, windowDays: Int, minimum: Double, active: Bool, cost: Double, checksum: String, status: SlotReservationStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.name = name
            self.windowDays = windowDays
            self.minimum = minimum
            self.active = active
            self.cost = cost
            self.checksum = checksum
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

        func canMoveTo(_ next: SlotReservationStatus) -> Bool {
            switch status {
            case .new:
                return next == SlotReservationStatus.running
            case .queued:
                return next == SlotReservationStatus.failed
            case .running:
                return next == SlotReservationStatus.failed
            case .done:
                return next == SlotReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("slot reservation") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(windowDays) - cost) * 100).rounded() / 100
        }

        func copyValue() -> SlotReservation {
            return SlotReservation(
                code: code,
                title: title,
                category: category,
                name: name,
                windowDays: windowDays,
                minimum: minimum,
                active: active,
                cost: cost,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a slot reservation in status new.
    static func newSlotReservation(_ code: String, title: String) -> SlotReservation {
        return SlotReservation(
            code: code,
            title: title,
            category: "",
            name: "",
            windowDays: 0,
            minimum: 0.0,
            active: false,
            cost: 0.0,
            checksum: "",
            status: SlotReservationStatus.new
        )
    }
}
