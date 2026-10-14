import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge notice is in its life cycle.
    enum ChargeNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A charge notice. Its code is unique within a tenant.
    final class ChargeNotice {
        var code: String
        var name: String
        var endsAt: Int
        var rate: Double
        var pinned: Bool
        var title: String
        var weight: Double
        var notes: String
        var facility: String
        var region: String
        var status: ChargeNoticeStatus

        init(code: String, name: String, endsAt: Int, rate: Double, pinned: Bool, title: String, weight: Double, notes: String, facility: String, region: String, status: ChargeNoticeStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.rate = rate
            self.pinned = pinned
            self.title = title
            self.weight = weight
            self.notes = notes
            self.facility = facility
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ChargeNoticeStatus) -> Bool {
            switch status {
            case .planned:
                return next == ChargeNoticeStatus.scheduled
            case .scheduled:
                return next == ChargeNoticeStatus.cancelled
            case .inProgress:
                return next == ChargeNoticeStatus.completed || next == ChargeNoticeStatus.cancelled
            case .completed:
                return next == ChargeNoticeStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("charge notice") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((weight - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeNotice {
            return ChargeNotice(
                code: code,
                name: name,
                endsAt: endsAt,
                rate: rate,
                pinned: pinned,
                title: title,
                weight: weight,
                notes: notes,
                facility: facility,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a charge notice in status planned.
    static func newChargeNotice(_ code: String, name: String) -> ChargeNotice {
        return ChargeNotice(
            code: code,
            name: name,
            endsAt: 0,
            rate: 0.0,
            pinned: false,
            title: "",
            weight: 0.0,
            notes: "",
            facility: "",
            region: "",
            status: ChargeNoticeStatus.planned
        )
    }
}
