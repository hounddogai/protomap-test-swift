import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive panel digest is in its life cycle.
    enum AdaptivePanelDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a adaptive panel digest and its current status.
    final class AdaptivePanelDigest {
        var code: String
        var title: String
        var startsAt: Int
        var cost: Double
        var summary: String
        var phone: String
        var rate: Double
        var clinicianID: String
        var tags: [String]
        var status: AdaptivePanelDigestStatus

        init(code: String, title: String, startsAt: Int, cost: Double, summary: String, phone: String, rate: Double, clinicianID: String, tags: [String], status: AdaptivePanelDigestStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.cost = cost
            self.summary = summary
            self.phone = phone
            self.rate = rate
            self.clinicianID = clinicianID
            self.tags = tags
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

        func canMoveTo(_ next: AdaptivePanelDigestStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptivePanelDigestStatus.pending || next == AdaptivePanelDigestStatus.active
            case .pending:
                return next == AdaptivePanelDigestStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptivePanelDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive panel digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
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

        func netLoad() -> Double {
            return (Double(startsAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePanelDigest {
            return AdaptivePanelDigest(
                code: code,
                title: title,
                startsAt: startsAt,
                cost: cost,
                summary: summary,
                phone: phone,
                rate: rate,
                clinicianID: clinicianID,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive panel digest in status draft.
    static func newAdaptivePanelDigest(_ code: String, title: String) -> AdaptivePanelDigest {
        return AdaptivePanelDigest(
            code: code,
            title: title,
            startsAt: 0,
            cost: 0.0,
            summary: "",
            phone: "",
            rate: 0.0,
            clinicianID: "",
            tags: [],
            status: AdaptivePanelDigestStatus.draft
        )
    }
}
