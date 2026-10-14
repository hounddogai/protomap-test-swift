import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol exception is in its life cycle.
    enum CareProtocolExceptionStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a care protocol exception and its current status.
    final class CareProtocolException {
        var code: String
        var name: String
        var checksum: String
        var updatedAt: Int
        var clinicianID: String
        var segment: String
        var notes: String
        var expiresAt: Int
        var status: CareProtocolExceptionStatus

        init(code: String, name: String, checksum: String, updatedAt: Int, clinicianID: String, segment: String, notes: String, expiresAt: Int, status: CareProtocolExceptionStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.updatedAt = updatedAt
            self.clinicianID = clinicianID
            self.segment = segment
            self.notes = notes
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CareProtocolExceptionStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareProtocolExceptionStatus.done
            case .done:
                return next == CareProtocolExceptionStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return (Double(updatedAt) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolException {
            return CareProtocolException(
                code: code,
                name: name,
                checksum: checksum,
                updatedAt: updatedAt,
                clinicianID: clinicianID,
                segment: segment,
                notes: notes,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a care protocol exception in status new.
    static func newCareProtocolException(_ code: String, name: String) -> CareProtocolException {
        return CareProtocolException(
            code: code,
            name: name,
            checksum: "",
            updatedAt: 0,
            clinicianID: "",
            segment: "",
            notes: "",
            expiresAt: 0,
            status: CareProtocolExceptionStatus.new
        )
    }
}
