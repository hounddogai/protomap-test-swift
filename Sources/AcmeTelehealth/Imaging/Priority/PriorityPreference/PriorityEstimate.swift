import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority estimate is in its life cycle.
    enum PriorityEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a priority estimate and its current status.
    final class PriorityEstimate {
        var code: String
        var label: String
        var weight: Double
        var channel: String
        var dosageMg: Double
        var externalRef: String
        var batchSize: Int
        var limit: Int
        var copay: Double
        var payer: String
        var status: PriorityEstimateStatus

        init(code: String, label: String, weight: Double, channel: String, dosageMg: Double, externalRef: String, batchSize: Int, limit: Int, copay: Double, payer: String, status: PriorityEstimateStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.channel = channel
            self.dosageMg = dosageMg
            self.externalRef = externalRef
            self.batchSize = batchSize
            self.limit = limit
            self.copay = copay
            self.payer = payer
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

        func canMoveTo(_ next: PriorityEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == PriorityEstimateStatus.pending || next == PriorityEstimateStatus.active
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PriorityEstimateStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PriorityEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return ((Double(limit) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityEstimate {
            return PriorityEstimate(
                code: code,
                label: label,
                weight: weight,
                channel: channel,
                dosageMg: dosageMg,
                externalRef: externalRef,
                batchSize: batchSize,
                limit: limit,
                copay: copay,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a priority estimate in status draft.
    static func newPriorityEstimate(_ code: String, label: String) -> PriorityEstimate {
        return PriorityEstimate(
            code: code,
            label: label,
            weight: 0.0,
            channel: "",
            dosageMg: 0.0,
            externalRef: "",
            batchSize: 0,
            limit: 0,
            copay: 0.0,
            payer: "",
            status: PriorityEstimateStatus.draft
        )
    }
}
