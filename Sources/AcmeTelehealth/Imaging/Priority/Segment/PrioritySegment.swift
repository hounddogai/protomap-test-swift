import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority segment is in its life cycle.
    enum PrioritySegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One priority segment, with what the planners need to act on it.
    final class PrioritySegment {
        var code: String
        var name: String
        var specialty: String
        var approved: Bool
        var quantity: Int
        var archived: Bool
        var windowDays: Int
        var visitMinutes: Int
        var tags: [String]
        var batchSize: Int
        var segment: String
        var status: PrioritySegmentStatus

        init(code: String, name: String, specialty: String, approved: Bool, quantity: Int, archived: Bool, windowDays: Int, visitMinutes: Int, tags: [String], batchSize: Int, segment: String, status: PrioritySegmentStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.approved = approved
            self.quantity = quantity
            self.archived = archived
            self.windowDays = windowDays
            self.visitMinutes = visitMinutes
            self.tags = tags
            self.batchSize = batchSize
            self.segment = segment
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

        func canMoveTo(_ next: PrioritySegmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrioritySegmentStatus.inReview || next == PrioritySegmentStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PrioritySegmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrioritySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return (Double(quantity) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> PrioritySegment {
            return PrioritySegment(
                code: code,
                name: name,
                specialty: specialty,
                approved: approved,
                quantity: quantity,
                archived: archived,
                windowDays: windowDays,
                visitMinutes: visitMinutes,
                tags: tags,
                batchSize: batchSize,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a priority segment in status open.
    static func newPrioritySegment(_ code: String, name: String) -> PrioritySegment {
        return PrioritySegment(
            code: code,
            name: name,
            specialty: "",
            approved: false,
            quantity: 0,
            archived: false,
            windowDays: 0,
            visitMinutes: 0,
            tags: [],
            batchSize: 0,
            segment: "",
            status: PrioritySegmentStatus.`open`
        )
    }
}
