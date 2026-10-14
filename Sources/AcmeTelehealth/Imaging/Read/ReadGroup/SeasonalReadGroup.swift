import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal read group is in its life cycle.
    enum SeasonalReadGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal read group as the read team keeps it.
    final class SeasonalReadGroup {
        var code: String
        var label: String
        var externalRef: String
        var score: Double
        var payer: String
        var quantity: Int
        var status: SeasonalReadGroupStatus

        init(code: String, label: String, externalRef: String, score: Double, payer: String, quantity: Int, status: SeasonalReadGroupStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.score = score
            self.payer = payer
            self.quantity = quantity
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

        func canMoveTo(_ next: SeasonalReadGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalReadGroupStatus.approved || next == SeasonalReadGroupStatus.withdrawn
            case .approved:
                return next == SeasonalReadGroupStatus.withdrawn
            case .rejected:
                return next == SeasonalReadGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalReadGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal read group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(quantity) - score) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalReadGroup {
            return SeasonalReadGroup(
                code: code,
                label: label,
                externalRef: externalRef,
                score: score,
                payer: payer,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal read group in status proposed.
    static func newSeasonalReadGroup(_ code: String, label: String) -> SeasonalReadGroup {
        return SeasonalReadGroup(
            code: code,
            label: label,
            externalRef: "",
            score: 0.0,
            payer: "",
            quantity: 0,
            status: SeasonalReadGroupStatus.proposed
        )
    }
}
