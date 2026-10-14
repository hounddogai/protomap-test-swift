import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study adjustment is in its life cycle.
    enum StudyAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One study adjustment, with what the planners need to act on it.
    final class StudyAdjustment {
        var code: String
        var title: String
        var pinned: Bool
        var retries: Int
        var copay: Double
        var visible: Bool
        var source: String
        var margin: Double
        var rate: Double
        var tags: [String]
        var status: StudyAdjustmentStatus

        init(code: String, title: String, pinned: Bool, retries: Int, copay: Double, visible: Bool, source: String, margin: Double, rate: Double, tags: [String], status: StudyAdjustmentStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.retries = retries
            self.copay = copay
            self.visible = visible
            self.source = source
            self.margin = margin
            self.rate = rate
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

        func canMoveTo(_ next: StudyAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StudyAdjustmentStatus.inReview || next == StudyAdjustmentStatus.reopened
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

        func moveTo(_ next: StudyAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return (margin * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> StudyAdjustment {
            return StudyAdjustment(
                code: code,
                title: title,
                pinned: pinned,
                retries: retries,
                copay: copay,
                visible: visible,
                source: source,
                margin: margin,
                rate: rate,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a study adjustment in status open.
    static func newStudyAdjustment(_ code: String, title: String) -> StudyAdjustment {
        return StudyAdjustment(
            code: code,
            title: title,
            pinned: false,
            retries: 0,
            copay: 0.0,
            visible: false,
            source: "",
            margin: 0.0,
            rate: 0.0,
            tags: [],
            status: StudyAdjustmentStatus.`open`
        )
    }
}
