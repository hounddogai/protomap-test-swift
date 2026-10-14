import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure segment is in its life cycle.
    enum ClosureSegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a closure segment and its current status.
    final class ClosureSegment {
        var code: String
        var title: String
        var facility: String
        var ratio: Double
        var threshold: Double
        var durationMinutes: Int
        var acuity: Int
        var name: String
        var revision: Int
        var status: ClosureSegmentStatus

        init(code: String, title: String, facility: String, ratio: Double, threshold: Double, durationMinutes: Int, acuity: Int, name: String, revision: Int, status: ClosureSegmentStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.ratio = ratio
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.acuity = acuity
            self.name = name
            self.revision = revision
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

        func canMoveTo(_ next: ClosureSegmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ClosureSegmentStatus.resolved || next == ClosureSegmentStatus.archived
            case .resolved:
                return next == ClosureSegmentStatus.archived
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

        func moveTo(_ next: ClosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((ratio - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ClosureSegment {
            return ClosureSegment(
                code: code,
                title: title,
                facility: facility,
                ratio: ratio,
                threshold: threshold,
                durationMinutes: durationMinutes,
                acuity: acuity,
                name: name,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a closure segment in status open.
    static func newClosureSegment(_ code: String, title: String) -> ClosureSegment {
        return ClosureSegment(
            code: code,
            title: title,
            facility: "",
            ratio: 0.0,
            threshold: 0.0,
            durationMinutes: 0,
            acuity: 0,
            name: "",
            revision: 0,
            status: ClosureSegmentStatus.`open`
        )
    }
}
