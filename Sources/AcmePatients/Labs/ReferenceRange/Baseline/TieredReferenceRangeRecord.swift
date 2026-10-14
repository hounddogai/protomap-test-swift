import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered reference range record is in its life cycle.
    enum TieredReferenceRangeRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a tiered reference range record and its current status.
    final class TieredReferenceRangeRecord {
        var code: String
        var title: String
        var batchSize: Int
        var priority: Int
        var capacity: Int
        var currency: String
        var summary: String
        var name: String
        var bed: String
        var region: String
        var diagnosisCode: String
        var status: TieredReferenceRangeRecordStatus

        init(code: String, title: String, batchSize: Int, priority: Int, capacity: Int, currency: String, summary: String, name: String, bed: String, region: String, diagnosisCode: String, status: TieredReferenceRangeRecordStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.priority = priority
            self.capacity = capacity
            self.currency = currency
            self.summary = summary
            self.name = name
            self.bed = bed
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredReferenceRangeRecordStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == TieredReferenceRangeRecordStatus.expired
            case .revoked:
                return next == TieredReferenceRangeRecordStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReferenceRangeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered reference range record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((Double(capacity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> TieredReferenceRangeRecord {
            return TieredReferenceRangeRecord(
                code: code,
                title: title,
                batchSize: batchSize,
                priority: priority,
                capacity: capacity,
                currency: currency,
                summary: summary,
                name: name,
                bed: bed,
                region: region,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered reference range record in status requested.
    static func newTieredReferenceRangeRecord(_ code: String, title: String) -> TieredReferenceRangeRecord {
        return TieredReferenceRangeRecord(
            code: code,
            title: title,
            batchSize: 0,
            priority: 0,
            capacity: 0,
            currency: "",
            summary: "",
            name: "",
            bed: "",
            region: "",
            diagnosisCode: "",
            status: TieredReferenceRangeRecordStatus.requested
        )
    }
}
