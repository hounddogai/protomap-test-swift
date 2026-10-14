import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual reference range assignment is in its life cycle.
    enum ManualReferenceRangeAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a manual reference range assignment and its current status.
    final class ManualReferenceRangeAssignment {
        var code: String
        var name: String
        var currency: String
        var startsAt: Int
        var maximum: Double
        var contactEmail: String
        var visitMinutes: Int
        var revision: Int
        var graceDays: Int
        var status: ManualReferenceRangeAssignmentStatus

        init(code: String, name: String, currency: String, startsAt: Int, maximum: Double, contactEmail: String, visitMinutes: Int, revision: Int, graceDays: Int, status: ManualReferenceRangeAssignmentStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.startsAt = startsAt
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.revision = revision
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ManualReferenceRangeAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == ManualReferenceRangeAssignmentStatus.running || next == ManualReferenceRangeAssignmentStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ManualReferenceRangeAssignmentStatus.done || next == ManualReferenceRangeAssignmentStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ManualReferenceRangeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual reference range assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return ((Double(visitMinutes) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ManualReferenceRangeAssignment {
            return ManualReferenceRangeAssignment(
                code: code,
                name: name,
                currency: currency,
                startsAt: startsAt,
                maximum: maximum,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                revision: revision,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual reference range assignment in status new.
    static func newManualReferenceRangeAssignment(_ code: String, name: String) -> ManualReferenceRangeAssignment {
        return ManualReferenceRangeAssignment(
            code: code,
            name: name,
            currency: "",
            startsAt: 0,
            maximum: 0.0,
            contactEmail: "",
            visitMinutes: 0,
            revision: 0,
            graceDays: 0,
            status: ManualReferenceRangeAssignmentStatus.new
        )
    }
}
