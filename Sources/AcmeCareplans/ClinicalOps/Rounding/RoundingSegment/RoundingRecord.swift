import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding record is in its life cycle.
    enum RoundingRecordStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rounding record as the rounding team keeps it.
    final class RoundingRecord {
        var code: String
        var label: String
        var limit: Int
        var approved: Bool
        var unit: String
        var ceiling: Double
        var revision: Int
        var visitMinutes: Int
        var quantity: Int
        var maximum: Double
        var status: RoundingRecordStatus

        init(code: String, label: String, limit: Int, approved: Bool, unit: String, ceiling: Double, revision: Int, visitMinutes: Int, quantity: Int, maximum: Double, status: RoundingRecordStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.approved = approved
            self.unit = unit
            self.ceiling = ceiling
            self.revision = revision
            self.visitMinutes = visitMinutes
            self.quantity = quantity
            self.maximum = maximum
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

        func canMoveTo(_ next: RoundingRecordStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RoundingRecordStatus.retired
            case .published:
                return next == RoundingRecordStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return ((Double(revision) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> RoundingRecord {
            return RoundingRecord(
                code: code,
                label: label,
                limit: limit,
                approved: approved,
                unit: unit,
                ceiling: ceiling,
                revision: revision,
                visitMinutes: visitMinutes,
                quantity: quantity,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rounding record in status created.
    static func newRoundingRecord(_ code: String, label: String) -> RoundingRecord {
        return RoundingRecord(
            code: code,
            label: label,
            limit: 0,
            approved: false,
            unit: "",
            ceiling: 0.0,
            revision: 0,
            visitMinutes: 0,
            quantity: 0,
            maximum: 0.0,
            status: RoundingRecordStatus.created
        )
    }
}
