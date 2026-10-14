import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled accession target is in its life cycle.
    enum ScheduledAccessionTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled accession target as the accession team keeps it.
    final class ScheduledAccessionTarget {
        var code: String
        var label: String
        var createdAt: Int
        var cost: Double
        var segment: String
        var maximum: Double
        var ceiling: Double
        var notes: String
        var status: ScheduledAccessionTargetStatus

        init(code: String, label: String, createdAt: Int, cost: Double, segment: String, maximum: Double, ceiling: Double, notes: String, status: ScheduledAccessionTargetStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.cost = cost
            self.segment = segment
            self.maximum = maximum
            self.ceiling = ceiling
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledAccessionTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledAccessionTargetStatus.rejected
            case .approved:
                return next == ScheduledAccessionTargetStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledAccessionTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled accession target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (maximum * cost * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAccessionTarget {
            return ScheduledAccessionTarget(
                code: code,
                label: label,
                createdAt: createdAt,
                cost: cost,
                segment: segment,
                maximum: maximum,
                ceiling: ceiling,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled accession target in status proposed.
    static func newScheduledAccessionTarget(_ code: String, label: String) -> ScheduledAccessionTarget {
        return ScheduledAccessionTarget(
            code: code,
            label: label,
            createdAt: 0,
            cost: 0.0,
            segment: "",
            maximum: 0.0,
            ceiling: 0.0,
            notes: "",
            status: ScheduledAccessionTargetStatus.proposed
        )
    }
}
