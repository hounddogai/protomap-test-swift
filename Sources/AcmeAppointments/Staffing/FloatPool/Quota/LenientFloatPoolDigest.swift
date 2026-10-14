import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient float pool digest is in its life cycle.
    enum LenientFloatPoolDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient float pool digest as the float pool team keeps it.
    final class LenientFloatPoolDigest {
        var code: String
        var name: String
        var phone: String
        var capacity: Int
        var ward: String
        var expiresAt: Int
        var sequence: Int
        var status: LenientFloatPoolDigestStatus

        init(code: String, name: String, phone: String, capacity: Int, ward: String, expiresAt: Int, sequence: Int, status: LenientFloatPoolDigestStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.capacity = capacity
            self.ward = ward
            self.expiresAt = expiresAt
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientFloatPoolDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientFloatPoolDigestStatus.running
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LenientFloatPoolDigestStatus.done || next == LenientFloatPoolDigestStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LenientFloatPoolDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient float pool digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient float pool digest") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(sequence) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientFloatPoolDigest {
            return LenientFloatPoolDigest(
                code: code,
                name: name,
                phone: phone,
                capacity: capacity,
                ward: ward,
                expiresAt: expiresAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient float pool digest in status new.
    static func newLenientFloatPoolDigest(_ code: String, name: String) -> LenientFloatPoolDigest {
        return LenientFloatPoolDigest(
            code: code,
            name: name,
            phone: "",
            capacity: 0,
            ward: "",
            expiresAt: 0,
            sequence: 0,
            status: LenientFloatPoolDigestStatus.new
        )
    }
}
