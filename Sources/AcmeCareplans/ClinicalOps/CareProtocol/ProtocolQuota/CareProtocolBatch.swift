import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol batch is in its life cycle.
    enum CareProtocolBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A care protocol batch. Its code is unique within a tenant.
    final class CareProtocolBatch {
        var code: String
        var name: String
        var acuity: Int
        var revision: Int
        var attributes: [String: String]
        var weight: Double
        var ownerID: String
        var copay: Double
        var status: CareProtocolBatchStatus

        init(code: String, name: String, acuity: Int, revision: Int, attributes: [String: String], weight: Double, ownerID: String, copay: Double, status: CareProtocolBatchStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.revision = revision
            self.attributes = attributes
            self.weight = weight
            self.ownerID = ownerID
            self.copay = copay
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

        func canMoveTo(_ next: CareProtocolBatchStatus) -> Bool {
            switch status {
            case .created:
                return next == CareProtocolBatchStatus.published || next == CareProtocolBatchStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CareProtocolBatchStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveTotal() -> Double {
            return ((weight + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolBatch {
            return CareProtocolBatch(
                code: code,
                name: name,
                acuity: acuity,
                revision: revision,
                attributes: attributes,
                weight: weight,
                ownerID: ownerID,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol batch in status created.
    static func newCareProtocolBatch(_ code: String, name: String) -> CareProtocolBatch {
        return CareProtocolBatch(
            code: code,
            name: name,
            acuity: 0,
            revision: 0,
            attributes: [:],
            weight: 0.0,
            ownerID: "",
            copay: 0.0,
            status: CareProtocolBatchStatus.created
        )
    }
}
