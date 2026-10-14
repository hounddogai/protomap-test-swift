import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary disclosure request is in its life cycle.
    enum PrimaryDisclosureRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary disclosure request and its current status.
    final class PrimaryDisclosureRequest {
        var code: String
        var name: String
        var batchSize: Int
        var title: String
        var procedureCode: String
        var payer: String
        var currency: String
        var encounterID: String
        var revision: Int
        var sequence: Int
        var region: String
        var status: PrimaryDisclosureRequestStatus

        init(code: String, name: String, batchSize: Int, title: String, procedureCode: String, payer: String, currency: String, encounterID: String, revision: Int, sequence: Int, region: String, status: PrimaryDisclosureRequestStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.title = title
            self.procedureCode = procedureCode
            self.payer = payer
            self.currency = currency
            self.encounterID = encounterID
            self.revision = revision
            self.sequence = sequence
            self.region = region
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

        func canMoveTo(_ next: PrimaryDisclosureRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryDisclosureRequestStatus.closed
            case .suspended:
                return next == PrimaryDisclosureRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryDisclosureRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary disclosure request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return (Double(revision) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDisclosureRequest {
            return PrimaryDisclosureRequest(
                code: code,
                name: name,
                batchSize: batchSize,
                title: title,
                procedureCode: procedureCode,
                payer: payer,
                currency: currency,
                encounterID: encounterID,
                revision: revision,
                sequence: sequence,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary disclosure request in status draft.
    static func newPrimaryDisclosureRequest(_ code: String, name: String) -> PrimaryDisclosureRequest {
        return PrimaryDisclosureRequest(
            code: code,
            name: name,
            batchSize: 0,
            title: "",
            procedureCode: "",
            payer: "",
            currency: "",
            encounterID: "",
            revision: 0,
            sequence: 0,
            region: "",
            status: PrimaryDisclosureRequestStatus.draft
        )
    }
}
