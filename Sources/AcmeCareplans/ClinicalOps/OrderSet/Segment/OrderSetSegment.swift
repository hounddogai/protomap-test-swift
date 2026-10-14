import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set segment is in its life cycle.
    enum OrderSetSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A order set segment as the order set team keeps it.
    final class OrderSetSegment {
        var code: String
        var title: String
        var locale: String
        var patientRef: String
        var clinicianID: String
        var pinned: Bool
        var revision: Int
        var acuity: Int
        var threshold: Double
        var status: OrderSetSegmentStatus

        init(code: String, title: String, locale: String, patientRef: String, clinicianID: String, pinned: Bool, revision: Int, acuity: Int, threshold: Double, status: OrderSetSegmentStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.patientRef = patientRef
            self.clinicianID = clinicianID
            self.pinned = pinned
            self.revision = revision
            self.acuity = acuity
            self.threshold = threshold
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

        func canMoveTo(_ next: OrderSetSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == OrderSetSegmentStatus.suspended
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == OrderSetSegmentStatus.suspended
            case .suspended:
                return next == OrderSetSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("order set segment") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(revision) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetSegment {
            return OrderSetSegment(
                code: code,
                title: title,
                locale: locale,
                patientRef: patientRef,
                clinicianID: clinicianID,
                pinned: pinned,
                revision: revision,
                acuity: acuity,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a order set segment in status draft.
    static func newOrderSetSegment(_ code: String, title: String) -> OrderSetSegment {
        return OrderSetSegment(
            code: code,
            title: title,
            locale: "",
            patientRef: "",
            clinicianID: "",
            pinned: false,
            revision: 0,
            acuity: 0,
            threshold: 0.0,
            status: OrderSetSegmentStatus.draft
        )
    }
}
