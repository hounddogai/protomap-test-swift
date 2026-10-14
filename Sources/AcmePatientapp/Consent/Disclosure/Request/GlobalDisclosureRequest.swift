import AcmePlatform
import Foundation

extension Consent {
    /// Where a global disclosure request is in its life cycle.
    enum GlobalDisclosureRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global disclosure request as the disclosure team keeps it.
    final class GlobalDisclosureRequest {
        var code: String
        var title: String
        var score: Double
        var tags: [String]
        var procedureCode: String
        var endsAt: Int
        var reviewer: String
        var refills: Int
        var status: GlobalDisclosureRequestStatus

        init(code: String, title: String, score: Double, tags: [String], procedureCode: String, endsAt: Int, reviewer: String, refills: Int, status: GlobalDisclosureRequestStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.tags = tags
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.refills = refills
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

        func canMoveTo(_ next: GlobalDisclosureRequestStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalDisclosureRequestStatus.inProgress || next == GlobalDisclosureRequestStatus.completed
            case .scheduled:
                return next == GlobalDisclosureRequestStatus.completed
            case .inProgress:
                return next == GlobalDisclosureRequestStatus.completed
            case .completed:
                return next == GlobalDisclosureRequestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDisclosureRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global disclosure request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((Double(refills) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDisclosureRequest {
            return GlobalDisclosureRequest(
                code: code,
                title: title,
                score: score,
                tags: tags,
                procedureCode: procedureCode,
                endsAt: endsAt,
                reviewer: reviewer,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global disclosure request in status planned.
    static func newGlobalDisclosureRequest(_ code: String, title: String) -> GlobalDisclosureRequest {
        return GlobalDisclosureRequest(
            code: code,
            title: title,
            score: 0.0,
            tags: [],
            procedureCode: "",
            endsAt: 0,
            reviewer: "",
            refills: 0,
            status: GlobalDisclosureRequestStatus.planned
        )
    }
}
