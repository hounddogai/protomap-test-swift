import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched modality mapping is in its life cycle.
    enum BatchedModalityMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A batched modality mapping. Its code is unique within a tenant.
    final class BatchedModalityMapping {
        var code: String
        var name: String
        var quantity: Int
        var durationMinutes: Int
        var visitMinutes: Int
        var patientRef: String
        var limit: Int
        var acuity: Int
        var encounterID: String
        var status: BatchedModalityMappingStatus

        init(code: String, name: String, quantity: Int, durationMinutes: Int, visitMinutes: Int, patientRef: String, limit: Int, acuity: Int, encounterID: String, status: BatchedModalityMappingStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.visitMinutes = visitMinutes
            self.patientRef = patientRef
            self.limit = limit
            self.acuity = acuity
            self.encounterID = encounterID
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

        func canMoveTo(_ next: BatchedModalityMappingStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == BatchedModalityMappingStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BatchedModalityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched modality mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return (Double(acuity) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> BatchedModalityMapping {
            return BatchedModalityMapping(
                code: code,
                name: name,
                quantity: quantity,
                durationMinutes: durationMinutes,
                visitMinutes: visitMinutes,
                patientRef: patientRef,
                limit: limit,
                acuity: acuity,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched modality mapping in status created.
    static func newBatchedModalityMapping(_ code: String, name: String) -> BatchedModalityMapping {
        return BatchedModalityMapping(
            code: code,
            name: name,
            quantity: 0,
            durationMinutes: 0,
            visitMinutes: 0,
            patientRef: "",
            limit: 0,
            acuity: 0,
            encounterID: "",
            status: BatchedModalityMappingStatus.created
        )
    }
}
