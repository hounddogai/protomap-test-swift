import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional read draft is in its life cycle.
    enum RegionalReadDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional read draft and its current status.
    final class RegionalReadDraft {
        var code: String
        var title: String
        var notes: String
        var updatedAt: Int
        var segment: String
        var ownerID: String
        var acuity: Int
        var visitMinutes: Int
        var facility: String
        var score: Double
        var status: RegionalReadDraftStatus

        init(code: String, title: String, notes: String, updatedAt: Int, segment: String, ownerID: String, acuity: Int, visitMinutes: Int, facility: String, score: Double, status: RegionalReadDraftStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.updatedAt = updatedAt
            self.segment = segment
            self.ownerID = ownerID
            self.acuity = acuity
            self.visitMinutes = visitMinutes
            self.facility = facility
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalReadDraftStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalReadDraftStatus.cancelled
            case .inProgress:
                return next == RegionalReadDraftStatus.completed || next == RegionalReadDraftStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RegionalReadDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional read draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return (Double(acuity) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RegionalReadDraft {
            return RegionalReadDraft(
                code: code,
                title: title,
                notes: notes,
                updatedAt: updatedAt,
                segment: segment,
                ownerID: ownerID,
                acuity: acuity,
                visitMinutes: visitMinutes,
                facility: facility,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a regional read draft in status planned.
    static func newRegionalReadDraft(_ code: String, title: String) -> RegionalReadDraft {
        return RegionalReadDraft(
            code: code,
            title: title,
            notes: "",
            updatedAt: 0,
            segment: "",
            ownerID: "",
            acuity: 0,
            visitMinutes: 0,
            facility: "",
            score: 0.0,
            status: RegionalReadDraftStatus.planned
        )
    }
}
