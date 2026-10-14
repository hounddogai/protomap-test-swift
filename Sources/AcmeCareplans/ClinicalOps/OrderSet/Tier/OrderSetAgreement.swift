import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set agreement is in its life cycle.
    enum OrderSetAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One order set agreement, with what the planners need to act on it.
    final class OrderSetAgreement {
        var code: String
        var title: String
        var active: Bool
        var endsAt: Int
        var quantity: Int
        var graceDays: Int
        var batchSize: Int
        var minimum: Double
        var amount: Double
        var dosageMg: Double
        var status: OrderSetAgreementStatus

        init(code: String, title: String, active: Bool, endsAt: Int, quantity: Int, graceDays: Int, batchSize: Int, minimum: Double, amount: Double, dosageMg: Double, status: OrderSetAgreementStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.endsAt = endsAt
            self.quantity = quantity
            self.graceDays = graceDays
            self.batchSize = batchSize
            self.minimum = minimum
            self.amount = amount
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: OrderSetAgreementStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == OrderSetAgreementStatus.done || next == OrderSetAgreementStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: OrderSetAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return (Double(quantity) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetAgreement {
            return OrderSetAgreement(
                code: code,
                title: title,
                active: active,
                endsAt: endsAt,
                quantity: quantity,
                graceDays: graceDays,
                batchSize: batchSize,
                minimum: minimum,
                amount: amount,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a order set agreement in status new.
    static func newOrderSetAgreement(_ code: String, title: String) -> OrderSetAgreement {
        return OrderSetAgreement(
            code: code,
            title: title,
            active: false,
            endsAt: 0,
            quantity: 0,
            graceDays: 0,
            batchSize: 0,
            minimum: 0.0,
            amount: 0.0,
            dosageMg: 0.0,
            status: OrderSetAgreementStatus.new
        )
    }
}
