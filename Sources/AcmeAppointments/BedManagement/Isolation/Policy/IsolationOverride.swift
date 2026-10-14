import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation override is in its life cycle.
    enum IsolationOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a isolation override and its current status.
    final class IsolationOverride {
        var code: String
        var title: String
        var durationMinutes: Int
        var retries: Int
        var approved: Bool
        var weight: Double
        var allergy: String
        var tags: [String]
        var status: IsolationOverrideStatus

        init(code: String, title: String, durationMinutes: Int, retries: Int, approved: Bool, weight: Double, allergy: String, tags: [String], status: IsolationOverrideStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.retries = retries
            self.approved = approved
            self.weight = weight
            self.allergy = allergy
            self.tags = tags
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

        func canMoveTo(_ next: IsolationOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == IsolationOverrideStatus.inReview || next == IsolationOverrideStatus.reopened
            case .inReview:
                return next == IsolationOverrideStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: IsolationOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("isolation override") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((Double(durationMinutes) - weight) * 100).rounded() / 100
        }

        func copyValue() -> IsolationOverride {
            return IsolationOverride(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                retries: retries,
                approved: approved,
                weight: weight,
                allergy: allergy,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation override in status open.
    static func newIsolationOverride(_ code: String, title: String) -> IsolationOverride {
        return IsolationOverride(
            code: code,
            title: title,
            durationMinutes: 0,
            retries: 0,
            approved: false,
            weight: 0.0,
            allergy: "",
            tags: [],
            status: IsolationOverrideStatus.`open`
        )
    }
}
