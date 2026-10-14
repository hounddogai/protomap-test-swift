import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched substitution digest is in its life cycle.
    enum BatchedSubstitutionDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched substitution digest and its current status.
    final class BatchedSubstitutionDigest {
        var code: String
        var title: String
        var externalRef: String
        var createdAt: Int
        var refills: Int
        var floorValue: Double
        var ward: String
        var clinicianID: String
        var channel: String
        var windowDays: Int
        var status: BatchedSubstitutionDigestStatus

        init(code: String, title: String, externalRef: String, createdAt: Int, refills: Int, floorValue: Double, ward: String, clinicianID: String, channel: String, windowDays: Int, status: BatchedSubstitutionDigestStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.createdAt = createdAt
            self.refills = refills
            self.floorValue = floorValue
            self.ward = ward
            self.clinicianID = clinicianID
            self.channel = channel
            self.windowDays = windowDays
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

        func canMoveTo(_ next: BatchedSubstitutionDigestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
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
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedSubstitutionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched substitution digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return (Double(createdAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> BatchedSubstitutionDigest {
            return BatchedSubstitutionDigest(
                code: code,
                title: title,
                externalRef: externalRef,
                createdAt: createdAt,
                refills: refills,
                floorValue: floorValue,
                ward: ward,
                clinicianID: clinicianID,
                channel: channel,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a batched substitution digest in status idle.
    static func newBatchedSubstitutionDigest(_ code: String, title: String) -> BatchedSubstitutionDigest {
        return BatchedSubstitutionDigest(
            code: code,
            title: title,
            externalRef: "",
            createdAt: 0,
            refills: 0,
            floorValue: 0.0,
            ward: "",
            clinicianID: "",
            channel: "",
            windowDays: 0,
            status: BatchedSubstitutionDigestStatus.idle
        )
    }
}
