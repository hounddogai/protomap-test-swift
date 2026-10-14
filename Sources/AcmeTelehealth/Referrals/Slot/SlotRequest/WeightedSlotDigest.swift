import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted slot digest is in its life cycle.
    enum WeightedSlotDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a weighted slot digest and its current status.
    final class WeightedSlotDigest {
        var code: String
        var name: String
        var phone: String
        var updatedAt: Int
        var rate: Double
        var payer: String
        var retries: Int
        var endsAt: Int
        var quantity: Int
        var limit: Int
        var status: WeightedSlotDigestStatus

        init(code: String, name: String, phone: String, updatedAt: Int, rate: Double, payer: String, retries: Int, endsAt: Int, quantity: Int, limit: Int, status: WeightedSlotDigestStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.updatedAt = updatedAt
            self.rate = rate
            self.payer = payer
            self.retries = retries
            self.endsAt = endsAt
            self.quantity = quantity
            self.limit = limit
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

        func canMoveTo(_ next: WeightedSlotDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WeightedSlotDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedSlotDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted slot digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted slot digest") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(limit) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedSlotDigest {
            return WeightedSlotDigest(
                code: code,
                name: name,
                phone: phone,
                updatedAt: updatedAt,
                rate: rate,
                payer: payer,
                retries: retries,
                endsAt: endsAt,
                quantity: quantity,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted slot digest in status new.
    static func newWeightedSlotDigest(_ code: String, name: String) -> WeightedSlotDigest {
        return WeightedSlotDigest(
            code: code,
            name: name,
            phone: "",
            updatedAt: 0,
            rate: 0.0,
            payer: "",
            retries: 0,
            endsAt: 0,
            quantity: 0,
            limit: 0,
            status: WeightedSlotDigestStatus.new
        )
    }
}
