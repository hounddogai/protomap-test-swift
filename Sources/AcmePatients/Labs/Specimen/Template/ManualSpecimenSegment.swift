import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual specimen segment is in its life cycle.
    enum ManualSpecimenSegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One manual specimen segment, with what the planners need to act on it.
    final class ManualSpecimenSegment {
        var code: String
        var title: String
        var priority: Int
        var contactEmail: String
        var reviewer: String
        var revision: Int
        var expiresAt: Int
        var updatedAt: Int
        var refills: Int
        var minimum: Double
        var status: ManualSpecimenSegmentStatus

        init(code: String, title: String, priority: Int, contactEmail: String, reviewer: String, revision: Int, expiresAt: Int, updatedAt: Int, refills: Int, minimum: Double, status: ManualSpecimenSegmentStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.contactEmail = contactEmail
            self.reviewer = reviewer
            self.revision = revision
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.refills = refills
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualSpecimenSegmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ManualSpecimenSegmentStatus.done || next == ManualSpecimenSegmentStatus.failed
            case .running:
                return next == ManualSpecimenSegmentStatus.done || next == ManualSpecimenSegmentStatus.failed
            case .done:
                return next == ManualSpecimenSegmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualSpecimenSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual specimen segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("manual specimen segment") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(revision) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ManualSpecimenSegment {
            return ManualSpecimenSegment(
                code: code,
                title: title,
                priority: priority,
                contactEmail: contactEmail,
                reviewer: reviewer,
                revision: revision,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                refills: refills,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual specimen segment in status new.
    static func newManualSpecimenSegment(_ code: String, title: String) -> ManualSpecimenSegment {
        return ManualSpecimenSegment(
            code: code,
            title: title,
            priority: 0,
            contactEmail: "",
            reviewer: "",
            revision: 0,
            expiresAt: 0,
            updatedAt: 0,
            refills: 0,
            minimum: 0.0,
            status: ManualSpecimenSegmentStatus.new
        )
    }
}
