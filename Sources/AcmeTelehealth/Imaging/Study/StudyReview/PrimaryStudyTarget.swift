import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary study target is in its life cycle.
    enum PrimaryStudyTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a primary study target and its current status.
    final class PrimaryStudyTarget {
        var code: String
        var label: String
        var checksum: String
        var currency: String
        var rate: Double
        var acuity: Int
        var ownerID: String
        var status: PrimaryStudyTargetStatus

        init(code: String, label: String, checksum: String, currency: String, rate: Double, acuity: Int, ownerID: String, status: PrimaryStudyTargetStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.currency = currency
            self.rate = rate
            self.acuity = acuity
            self.ownerID = ownerID
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

        func canMoveTo(_ next: PrimaryStudyTargetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == PrimaryStudyTargetStatus.retired
            case .published:
                return next == PrimaryStudyTargetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryStudyTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary study target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((rate - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryStudyTarget {
            return PrimaryStudyTarget(
                code: code,
                label: label,
                checksum: checksum,
                currency: currency,
                rate: rate,
                acuity: acuity,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary study target in status created.
    static func newPrimaryStudyTarget(_ code: String, label: String) -> PrimaryStudyTarget {
        return PrimaryStudyTarget(
            code: code,
            label: label,
            checksum: "",
            currency: "",
            rate: 0.0,
            acuity: 0,
            ownerID: "",
            status: PrimaryStudyTargetStatus.created
        )
    }
}
