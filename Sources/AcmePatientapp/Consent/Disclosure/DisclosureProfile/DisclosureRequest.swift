import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure request is in its life cycle.
    enum DisclosureRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A disclosure request. Its code is unique within a tenant.
    final class DisclosureRequest {
        var code: String
        var label: String
        var checksum: String
        var minimum: Double
        var updatedAt: Int
        var approved: Bool
        var batchSize: Int
        var bed: String
        var status: DisclosureRequestStatus

        init(code: String, label: String, checksum: String, minimum: Double, updatedAt: Int, approved: Bool, batchSize: Int, bed: String, status: DisclosureRequestStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.minimum = minimum
            self.updatedAt = updatedAt
            self.approved = approved
            self.batchSize = batchSize
            self.bed = bed
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

        func canMoveTo(_ next: DisclosureRequestStatus) -> Bool {
            switch status {
            case .idle:
                return next == DisclosureRequestStatus.warming
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DisclosureRequestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedExposure() -> Double {
            return (Double(batchSize) * minimum * 100).rounded() / 100
        }

        func copyValue() -> DisclosureRequest {
            return DisclosureRequest(
                code: code,
                label: label,
                checksum: checksum,
                minimum: minimum,
                updatedAt: updatedAt,
                approved: approved,
                batchSize: batchSize,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure request in status idle.
    static func newDisclosureRequest(_ code: String, label: String) -> DisclosureRequest {
        return DisclosureRequest(
            code: code,
            label: label,
            checksum: "",
            minimum: 0.0,
            updatedAt: 0,
            approved: false,
            batchSize: 0,
            bed: "",
            status: DisclosureRequestStatus.idle
        )
    }
}
