import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census batch is in its life cycle.
    enum CensusBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a census batch and its current status.
    final class CensusBatch {
        var code: String
        var name: String
        var source: String
        var payer: String
        var currency: String
        var cost: Double
        var limit: Int
        var region: String
        var status: CensusBatchStatus

        init(code: String, name: String, source: String, payer: String, currency: String, cost: Double, limit: Int, region: String, status: CensusBatchStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.payer = payer
            self.currency = currency
            self.cost = cost
            self.limit = limit
            self.region = region
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

        func canMoveTo(_ next: CensusBatchStatus) -> Bool {
            switch status {
            case .new:
                return next == CensusBatchStatus.failed
            case .queued:
                switch next {
                case .running, .done:
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

        func moveTo(_ next: CensusBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("census batch") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(limit) + cost) * 100).rounded() / 100
        }

        func copyValue() -> CensusBatch {
            return CensusBatch(
                code: code,
                name: name,
                source: source,
                payer: payer,
                currency: currency,
                cost: cost,
                limit: limit,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a census batch in status new.
    static func newCensusBatch(_ code: String, name: String) -> CensusBatch {
        return CensusBatch(
            code: code,
            name: name,
            source: "",
            payer: "",
            currency: "",
            cost: 0.0,
            limit: 0,
            region: "",
            status: CensusBatchStatus.new
        )
    }
}
