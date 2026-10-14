import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered read batch is in its life cycle.
    enum TieredReadBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A tiered read batch. Its code is unique within a tenant.
    final class TieredReadBatch {
        var code: String
        var label: String
        var quantity: Int
        var minimum: Double
        var rate: Double
        var country: String
        var ownerID: String
        var floorValue: Double
        var batchSize: Int
        var score: Double
        var status: TieredReadBatchStatus

        init(code: String, label: String, quantity: Int, minimum: Double, rate: Double, country: String, ownerID: String, floorValue: Double, batchSize: Int, score: Double, status: TieredReadBatchStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.minimum = minimum
            self.rate = rate
            self.country = country
            self.ownerID = ownerID
            self.floorValue = floorValue
            self.batchSize = batchSize
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredReadBatchStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == TieredReadBatchStatus.resolved || next == TieredReadBatchStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: TieredReadBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered read batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered read batch") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(quantity) + rate) * 100).rounded() / 100
        }

        func copyValue() -> TieredReadBatch {
            return TieredReadBatch(
                code: code,
                label: label,
                quantity: quantity,
                minimum: minimum,
                rate: rate,
                country: country,
                ownerID: ownerID,
                floorValue: floorValue,
                batchSize: batchSize,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered read batch in status open.
    static func newTieredReadBatch(_ code: String, label: String) -> TieredReadBatch {
        return TieredReadBatch(
            code: code,
            label: label,
            quantity: 0,
            minimum: 0.0,
            rate: 0.0,
            country: "",
            ownerID: "",
            floorValue: 0.0,
            batchSize: 0,
            score: 0.0,
            status: TieredReadBatchStatus.`open`
        )
    }
}
