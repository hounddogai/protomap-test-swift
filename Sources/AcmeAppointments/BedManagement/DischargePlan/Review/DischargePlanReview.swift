import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan review is in its life cycle.
    enum DischargePlanReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A discharge plan review. Its code is unique within a tenant.
    final class DischargePlanReview {
        var code: String
        var title: String
        var phone: String
        var version: Int
        var limit: Int
        var ceiling: Double
        var floorValue: Double
        var revision: Int
        var contactEmail: String
        var graceDays: Int
        var bed: String
        var status: DischargePlanReviewStatus

        init(code: String, title: String, phone: String, version: Int, limit: Int, ceiling: Double, floorValue: Double, revision: Int, contactEmail: String, graceDays: Int, bed: String, status: DischargePlanReviewStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.version = version
            self.limit = limit
            self.ceiling = ceiling
            self.floorValue = floorValue
            self.revision = revision
            self.contactEmail = contactEmail
            self.graceDays = graceDays
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanReviewStatus) -> Bool {
            switch status {
            case .created:
                return next == DischargePlanReviewStatus.validated || next == DischargePlanReviewStatus.published
            case .validated:
                return next == DischargePlanReviewStatus.published || next == DischargePlanReviewStatus.retired
            case .published:
                return next == DischargePlanReviewStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return (Double(limit) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanReview {
            return DischargePlanReview(
                code: code,
                title: title,
                phone: phone,
                version: version,
                limit: limit,
                ceiling: ceiling,
                floorValue: floorValue,
                revision: revision,
                contactEmail: contactEmail,
                graceDays: graceDays,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan review in status created.
    static func newDischargePlanReview(_ code: String, title: String) -> DischargePlanReview {
        return DischargePlanReview(
            code: code,
            title: title,
            phone: "",
            version: 0,
            limit: 0,
            ceiling: 0.0,
            floorValue: 0.0,
            revision: 0,
            contactEmail: "",
            graceDays: 0,
            bed: "",
            status: DischargePlanReviewStatus.created
        )
    }
}
