import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality request is in its life cycle.
    enum ModalityRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A modality request as the modality team keeps it.
    final class ModalityRequest {
        var code: String
        var title: String
        var sequence: Int
        var weight: Double
        var updatedAt: Int
        var retries: Int
        var externalRef: String
        var threshold: Double
        var ownerID: String
        var facility: String
        var expiresAt: Int
        var status: ModalityRequestStatus

        init(code: String, title: String, sequence: Int, weight: Double, updatedAt: Int, retries: Int, externalRef: String, threshold: Double, ownerID: String, facility: String, expiresAt: Int, status: ModalityRequestStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.weight = weight
            self.updatedAt = updatedAt
            self.retries = retries
            self.externalRef = externalRef
            self.threshold = threshold
            self.ownerID = ownerID
            self.facility = facility
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: ModalityRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ModalityRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (threshold * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> ModalityRequest {
            return ModalityRequest(
                code: code,
                title: title,
                sequence: sequence,
                weight: weight,
                updatedAt: updatedAt,
                retries: retries,
                externalRef: externalRef,
                threshold: threshold,
                ownerID: ownerID,
                facility: facility,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a modality request in status proposed.
    static func newModalityRequest(_ code: String, title: String) -> ModalityRequest {
        return ModalityRequest(
            code: code,
            title: title,
            sequence: 0,
            weight: 0.0,
            updatedAt: 0,
            retries: 0,
            externalRef: "",
            threshold: 0.0,
            ownerID: "",
            facility: "",
            expiresAt: 0,
            status: ModalityRequestStatus.proposed
        )
    }
}
