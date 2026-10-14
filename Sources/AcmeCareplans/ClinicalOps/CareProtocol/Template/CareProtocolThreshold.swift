import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol threshold is in its life cycle.
    enum CareProtocolThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a care protocol threshold and its current status.
    final class CareProtocolThreshold {
        var code: String
        var title: String
        var label: String
        var amount: Double
        var dosageMg: Double
        var rate: Double
        var notes: String
        var status: CareProtocolThresholdStatus

        init(code: String, title: String, label: String, amount: Double, dosageMg: Double, rate: Double, notes: String, status: CareProtocolThresholdStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.amount = amount
            self.dosageMg = dosageMg
            self.rate = rate
            self.notes = notes
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

        func canMoveTo(_ next: CareProtocolThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CareProtocolThresholdStatus.reopened || next == CareProtocolThresholdStatus.archived
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

        func moveTo(_ next: CareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func weightedVolume() -> Double {
            return (rate * amount * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolThreshold {
            return CareProtocolThreshold(
                code: code,
                title: title,
                label: label,
                amount: amount,
                dosageMg: dosageMg,
                rate: rate,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol threshold in status open.
    static func newCareProtocolThreshold(_ code: String, title: String) -> CareProtocolThreshold {
        return CareProtocolThreshold(
            code: code,
            title: title,
            label: "",
            amount: 0.0,
            dosageMg: 0.0,
            rate: 0.0,
            notes: "",
            status: CareProtocolThresholdStatus.`open`
        )
    }
}
