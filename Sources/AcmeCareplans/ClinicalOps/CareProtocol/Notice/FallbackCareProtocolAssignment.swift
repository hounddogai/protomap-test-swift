import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback care protocol assignment is in its life cycle.
    enum FallbackCareProtocolAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback care protocol assignment. Its code is unique within a tenant.
    final class FallbackCareProtocolAssignment {
        var code: String
        var label: String
        var refills: Int
        var threshold: Double
        var ward: String
        var tags: [String]
        var graceDays: Int
        var endsAt: Int
        var budget: Double
        var ceiling: Double
        var batchSize: Int
        var status: FallbackCareProtocolAssignmentStatus

        init(code: String, label: String, refills: Int, threshold: Double, ward: String, tags: [String], graceDays: Int, endsAt: Int, budget: Double, ceiling: Double, batchSize: Int, status: FallbackCareProtocolAssignmentStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.threshold = threshold
            self.ward = ward
            self.tags = tags
            self.graceDays = graceDays
            self.endsAt = endsAt
            self.budget = budget
            self.ceiling = ceiling
            self.batchSize = batchSize
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

        func canMoveTo(_ next: FallbackCareProtocolAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackCareProtocolAssignmentStatus.scheduled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FallbackCareProtocolAssignmentStatus.completed || next == FallbackCareProtocolAssignmentStatus.cancelled
            case .completed:
                return next == FallbackCareProtocolAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCareProtocolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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
            return ((budget + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareProtocolAssignment {
            return FallbackCareProtocolAssignment(
                code: code,
                label: label,
                refills: refills,
                threshold: threshold,
                ward: ward,
                tags: tags,
                graceDays: graceDays,
                endsAt: endsAt,
                budget: budget,
                ceiling: ceiling,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback care protocol assignment in status planned.
    static func newFallbackCareProtocolAssignment(_ code: String, label: String) -> FallbackCareProtocolAssignment {
        return FallbackCareProtocolAssignment(
            code: code,
            label: label,
            refills: 0,
            threshold: 0.0,
            ward: "",
            tags: [],
            graceDays: 0,
            endsAt: 0,
            budget: 0.0,
            ceiling: 0.0,
            batchSize: 0,
            status: FallbackCareProtocolAssignmentStatus.planned
        )
    }
}
