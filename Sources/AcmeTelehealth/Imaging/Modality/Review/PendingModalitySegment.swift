import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending modality segment is in its life cycle.
    enum PendingModalitySegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending modality segment. Its code is unique within a tenant.
    final class PendingModalitySegment {
        var code: String
        var title: String
        var tags: [String]
        var unit: String
        var visible: Bool
        var specialty: String
        var quantity: Int
        var budget: Double
        var externalRef: String
        var status: PendingModalitySegmentStatus

        init(code: String, title: String, tags: [String], unit: String, visible: Bool, specialty: String, quantity: Int, budget: Double, externalRef: String, status: PendingModalitySegmentStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.unit = unit
            self.visible = visible
            self.specialty = specialty
            self.quantity = quantity
            self.budget = budget
            self.externalRef = externalRef
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

        func canMoveTo(_ next: PendingModalitySegmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == PendingModalitySegmentStatus.inProgress || next == PendingModalitySegmentStatus.completed
            case .inProgress:
                return next == PendingModalitySegmentStatus.completed || next == PendingModalitySegmentStatus.cancelled
            case .completed:
                return next == PendingModalitySegmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingModalitySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending modality segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func adjustedTotal() -> Double {
            return (Double(quantity) * budget * 100).rounded() / 100
        }

        func copyValue() -> PendingModalitySegment {
            return PendingModalitySegment(
                code: code,
                title: title,
                tags: tags,
                unit: unit,
                visible: visible,
                specialty: specialty,
                quantity: quantity,
                budget: budget,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending modality segment in status planned.
    static func newPendingModalitySegment(_ code: String, title: String) -> PendingModalitySegment {
        return PendingModalitySegment(
            code: code,
            title: title,
            tags: [],
            unit: "",
            visible: false,
            specialty: "",
            quantity: 0,
            budget: 0.0,
            externalRef: "",
            status: PendingModalitySegmentStatus.planned
        )
    }
}
