import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census plan is in its life cycle.
    enum CensusPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A census plan. Its code is unique within a tenant.
    final class CensusPlan {
        var code: String
        var title: String
        var encounterID: String
        var minimum: Double
        var tags: [String]
        var notes: String
        var durationMinutes: Int
        var payer: String
        var status: CensusPlanStatus

        init(code: String, title: String, encounterID: String, minimum: Double, tags: [String], notes: String, durationMinutes: Int, payer: String, status: CensusPlanStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.minimum = minimum
            self.tags = tags
            self.notes = notes
            self.durationMinutes = durationMinutes
            self.payer = payer
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

        func canMoveTo(_ next: CensusPlanStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CensusPlanStatus.inReview
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CensusPlanStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (minimum * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> CensusPlan {
            return CensusPlan(
                code: code,
                title: title,
                encounterID: encounterID,
                minimum: minimum,
                tags: tags,
                notes: notes,
                durationMinutes: durationMinutes,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a census plan in status open.
    static func newCensusPlan(_ code: String, title: String) -> CensusPlan {
        return CensusPlan(
            code: code,
            title: title,
            encounterID: "",
            minimum: 0.0,
            tags: [],
            notes: "",
            durationMinutes: 0,
            payer: "",
            status: CensusPlanStatus.`open`
        )
    }
}
