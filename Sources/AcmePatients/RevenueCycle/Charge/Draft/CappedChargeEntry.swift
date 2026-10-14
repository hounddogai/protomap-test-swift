import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped charge entry is in its life cycle.
    enum CappedChargeEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped charge entry, with what the planners need to act on it.
    final class CappedChargeEntry {
        var code: String
        var title: String
        var copay: Double
        var durationMinutes: Int
        var version: Int
        var batchSize: Int
        var category: String
        var visitMinutes: Int
        var notes: String
        var facility: String
        var diagnosisCode: String
        var status: CappedChargeEntryStatus

        init(code: String, title: String, copay: Double, durationMinutes: Int, version: Int, batchSize: Int, category: String, visitMinutes: Int, notes: String, facility: String, diagnosisCode: String, status: CappedChargeEntryStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.version = version
            self.batchSize = batchSize
            self.category = category
            self.visitMinutes = visitMinutes
            self.notes = notes
            self.facility = facility
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: CappedChargeEntryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CappedChargeEntryStatus.completed || next == CappedChargeEntryStatus.cancelled
            case .inProgress:
                return next == CappedChargeEntryStatus.completed || next == CappedChargeEntryStatus.cancelled
            case .completed:
                return next == CappedChargeEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedChargeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped charge entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("capped charge entry") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(version) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> CappedChargeEntry {
            return CappedChargeEntry(
                code: code,
                title: title,
                copay: copay,
                durationMinutes: durationMinutes,
                version: version,
                batchSize: batchSize,
                category: category,
                visitMinutes: visitMinutes,
                notes: notes,
                facility: facility,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a capped charge entry in status planned.
    static func newCappedChargeEntry(_ code: String, title: String) -> CappedChargeEntry {
        return CappedChargeEntry(
            code: code,
            title: title,
            copay: 0.0,
            durationMinutes: 0,
            version: 0,
            batchSize: 0,
            category: "",
            visitMinutes: 0,
            notes: "",
            facility: "",
            diagnosisCode: "",
            status: CappedChargeEntryStatus.planned
        )
    }
}
