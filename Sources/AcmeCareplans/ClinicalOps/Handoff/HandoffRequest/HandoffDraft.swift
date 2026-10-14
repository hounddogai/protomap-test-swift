import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff draft is in its life cycle.
    enum HandoffDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a handoff draft and its current status.
    final class HandoffDraft {
        var code: String
        var label: String
        var startsAt: Int
        var ward: String
        var refills: Int
        var cost: Double
        var allergy: String
        var ownerID: String
        var status: HandoffDraftStatus

        init(code: String, label: String, startsAt: Int, ward: String, refills: Int, cost: Double, allergy: String, ownerID: String, status: HandoffDraftStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.ward = ward
            self.refills = refills
            self.cost = cost
            self.allergy = allergy
            self.ownerID = ownerID
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

        func canMoveTo(_ next: HandoffDraftStatus) -> Bool {
            switch status {
            case .`open`:
                return next == HandoffDraftStatus.resolved || next == HandoffDraftStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == HandoffDraftStatus.reopened
            case .reopened:
                return next == HandoffDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return ((Double(startsAt) + cost) * 100).rounded() / 100
        }

        func copyValue() -> HandoffDraft {
            return HandoffDraft(
                code: code,
                label: label,
                startsAt: startsAt,
                ward: ward,
                refills: refills,
                cost: cost,
                allergy: allergy,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a handoff draft in status open.
    static func newHandoffDraft(_ code: String, label: String) -> HandoffDraft {
        return HandoffDraft(
            code: code,
            label: label,
            startsAt: 0,
            ward: "",
            refills: 0,
            cost: 0.0,
            allergy: "",
            ownerID: "",
            status: HandoffDraftStatus.`open`
        )
    }
}
