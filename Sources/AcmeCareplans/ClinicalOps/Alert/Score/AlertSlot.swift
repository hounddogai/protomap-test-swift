import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert slot is in its life cycle.
    enum AlertSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A alert slot as the alert team keeps it.
    final class AlertSlot {
        var code: String
        var title: String
        var limit: Int
        var payer: String
        var priority: Int
        var discount: Double
        var startsAt: Int
        var dosageMg: Double
        var endsAt: Int
        var status: AlertSlotStatus

        init(code: String, title: String, limit: Int, payer: String, priority: Int, discount: Double, startsAt: Int, dosageMg: Double, endsAt: Int, status: AlertSlotStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.payer = payer
            self.priority = priority
            self.discount = discount
            self.startsAt = startsAt
            self.dosageMg = dosageMg
            self.endsAt = endsAt
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

        func canMoveTo(_ next: AlertSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == AlertSlotStatus.published || next == AlertSlotStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AlertSlotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("alert slot") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(priority) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AlertSlot {
            return AlertSlot(
                code: code,
                title: title,
                limit: limit,
                payer: payer,
                priority: priority,
                discount: discount,
                startsAt: startsAt,
                dosageMg: dosageMg,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert slot in status created.
    static func newAlertSlot(_ code: String, title: String) -> AlertSlot {
        return AlertSlot(
            code: code,
            title: title,
            limit: 0,
            payer: "",
            priority: 0,
            discount: 0.0,
            startsAt: 0,
            dosageMg: 0.0,
            endsAt: 0,
            status: AlertSlotStatus.created
        )
    }
}
