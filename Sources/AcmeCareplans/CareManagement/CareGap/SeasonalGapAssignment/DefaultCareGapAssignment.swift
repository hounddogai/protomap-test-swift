import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default care gap assignment is in its life cycle.
    enum DefaultCareGapAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default care gap assignment. Its code is unique within a tenant.
    final class DefaultCareGapAssignment {
        var code: String
        var name: String
        var capacity: Int
        var country: String
        var windowDays: Int
        var limit: Int
        var ratio: Double
        var copay: Double
        var contactEmail: String
        var archived: Bool
        var status: DefaultCareGapAssignmentStatus

        init(code: String, name: String, capacity: Int, country: String, windowDays: Int, limit: Int, ratio: Double, copay: Double, contactEmail: String, archived: Bool, status: DefaultCareGapAssignmentStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.country = country
            self.windowDays = windowDays
            self.limit = limit
            self.ratio = ratio
            self.copay = copay
            self.contactEmail = contactEmail
            self.archived = archived
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

        func canMoveTo(_ next: DefaultCareGapAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultCareGapAssignmentStatus.inProgress || next == DefaultCareGapAssignmentStatus.completed
            case .scheduled:
                return next == DefaultCareGapAssignmentStatus.completed || next == DefaultCareGapAssignmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultCareGapAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care gap assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default care gap assignment") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(capacity) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareGapAssignment {
            return DefaultCareGapAssignment(
                code: code,
                name: name,
                capacity: capacity,
                country: country,
                windowDays: windowDays,
                limit: limit,
                ratio: ratio,
                copay: copay,
                contactEmail: contactEmail,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default care gap assignment in status planned.
    static func newDefaultCareGapAssignment(_ code: String, name: String) -> DefaultCareGapAssignment {
        return DefaultCareGapAssignment(
            code: code,
            name: name,
            capacity: 0,
            country: "",
            windowDays: 0,
            limit: 0,
            ratio: 0.0,
            copay: 0.0,
            contactEmail: "",
            archived: false,
            status: DefaultCareGapAssignmentStatus.planned
        )
    }
}
