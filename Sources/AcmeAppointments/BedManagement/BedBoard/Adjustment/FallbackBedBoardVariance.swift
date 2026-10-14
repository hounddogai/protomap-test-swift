import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback bed board variance is in its life cycle.
    enum FallbackBedBoardVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a fallback bed board variance and its current status.
    final class FallbackBedBoardVariance {
        var code: String
        var name: String
        var segment: String
        var bed: String
        var title: String
        var channel: String
        var archived: Bool
        var source: String
        var payer: String
        var amount: Double
        var status: FallbackBedBoardVarianceStatus

        init(code: String, name: String, segment: String, bed: String, title: String, channel: String, archived: Bool, source: String, payer: String, amount: Double, status: FallbackBedBoardVarianceStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.bed = bed
            self.title = title
            self.channel = channel
            self.archived = archived
            self.source = source
            self.payer = payer
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackBedBoardVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackBedBoardVarianceStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FallbackBedBoardVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback bed board variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback bed board variance") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> FallbackBedBoardVariance {
            return FallbackBedBoardVariance(
                code: code,
                name: name,
                segment: segment,
                bed: bed,
                title: title,
                channel: channel,
                archived: archived,
                source: source,
                payer: payer,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback bed board variance in status proposed.
    static func newFallbackBedBoardVariance(_ code: String, name: String) -> FallbackBedBoardVariance {
        return FallbackBedBoardVariance(
            code: code,
            name: name,
            segment: "",
            bed: "",
            title: "",
            channel: "",
            archived: false,
            source: "",
            payer: "",
            amount: 0.0,
            status: FallbackBedBoardVarianceStatus.proposed
        )
    }
}
