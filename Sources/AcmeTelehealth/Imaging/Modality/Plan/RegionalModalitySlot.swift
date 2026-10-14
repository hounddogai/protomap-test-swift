import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional modality slot is in its life cycle.
    enum RegionalModalitySlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a regional modality slot and its current status.
    final class RegionalModalitySlot {
        var code: String
        var label: String
        var graceDays: Int
        var acuity: Int
        var ownerID: String
        var ratio: Double
        var reviewer: String
        var contactEmail: String
        var status: RegionalModalitySlotStatus

        init(code: String, label: String, graceDays: Int, acuity: Int, ownerID: String, ratio: Double, reviewer: String, contactEmail: String, status: RegionalModalitySlotStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.acuity = acuity
            self.ownerID = ownerID
            self.ratio = ratio
            self.reviewer = reviewer
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: RegionalModalitySlotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RegionalModalitySlotStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RegionalModalitySlotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalModalitySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional modality slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedTotal() -> Double {
            return (ratio * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> RegionalModalitySlot {
            return RegionalModalitySlot(
                code: code,
                label: label,
                graceDays: graceDays,
                acuity: acuity,
                ownerID: ownerID,
                ratio: ratio,
                reviewer: reviewer,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional modality slot in status open.
    static func newRegionalModalitySlot(_ code: String, label: String) -> RegionalModalitySlot {
        return RegionalModalitySlot(
            code: code,
            label: label,
            graceDays: 0,
            acuity: 0,
            ownerID: "",
            ratio: 0.0,
            reviewer: "",
            contactEmail: "",
            status: RegionalModalitySlotStatus.`open`
        )
    }
}
