import AcmePlatform
import Foundation

extension Labs {
    /// Where a default specimen quota is in its life cycle.
    enum DefaultSpecimenQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default specimen quota and its current status.
    final class DefaultSpecimenQuota {
        var code: String
        var label: String
        var expiresAt: Int
        var ward: String
        var maximum: Double
        var ownerID: String
        var sequence: Int
        var status: DefaultSpecimenQuotaStatus

        init(code: String, label: String, expiresAt: Int, ward: String, maximum: Double, ownerID: String, sequence: Int, status: DefaultSpecimenQuotaStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.ward = ward
            self.maximum = maximum
            self.ownerID = ownerID
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultSpecimenQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DefaultSpecimenQuotaStatus.draining
            case .ready:
                return next == DefaultSpecimenQuotaStatus.stopped
            case .draining:
                return next == DefaultSpecimenQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultSpecimenQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default specimen quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedTotal() -> Double {
            return (Double(sequence) * maximum * 100).rounded() / 100
        }

        func copyValue() -> DefaultSpecimenQuota {
            return DefaultSpecimenQuota(
                code: code,
                label: label,
                expiresAt: expiresAt,
                ward: ward,
                maximum: maximum,
                ownerID: ownerID,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default specimen quota in status idle.
    static func newDefaultSpecimenQuota(_ code: String, label: String) -> DefaultSpecimenQuota {
        return DefaultSpecimenQuota(
            code: code,
            label: label,
            expiresAt: 0,
            ward: "",
            maximum: 0.0,
            ownerID: "",
            sequence: 0,
            status: DefaultSpecimenQuotaStatus.idle
        )
    }
}
