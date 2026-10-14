import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set digest is in its life cycle.
    enum OrderSetDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A order set digest. Its code is unique within a tenant.
    final class OrderSetDigest {
        var code: String
        var title: String
        var region: String
        var currency: String
        var batchSize: Int
        var description: String
        var patientRef: String
        var revision: Int
        var bed: String
        var allergy: String
        var windowDays: Int
        var status: OrderSetDigestStatus

        init(code: String, title: String, region: String, currency: String, batchSize: Int, description: String, patientRef: String, revision: Int, bed: String, allergy: String, windowDays: Int, status: OrderSetDigestStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.currency = currency
            self.batchSize = batchSize
            self.description = description
            self.patientRef = patientRef
            self.revision = revision
            self.bed = bed
            self.allergy = allergy
            self.windowDays = windowDays
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

        func canMoveTo(_ next: OrderSetDigestStatus) -> Bool {
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
                return next == OrderSetDigestStatus.inProgress || next == OrderSetDigestStatus.completed
            case .inProgress:
                return next == OrderSetDigestStatus.cancelled
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

        func moveTo(_ next: OrderSetDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("order set digest") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(windowDays) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetDigest {
            return OrderSetDigest(
                code: code,
                title: title,
                region: region,
                currency: currency,
                batchSize: batchSize,
                description: description,
                patientRef: patientRef,
                revision: revision,
                bed: bed,
                allergy: allergy,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a order set digest in status planned.
    static func newOrderSetDigest(_ code: String, title: String) -> OrderSetDigest {
        return OrderSetDigest(
            code: code,
            title: title,
            region: "",
            currency: "",
            batchSize: 0,
            description: "",
            patientRef: "",
            revision: 0,
            bed: "",
            allergy: "",
            windowDays: 0,
            status: OrderSetDigestStatus.planned
        )
    }
}
