import AcmePlatform
import Foundation

extension Consent {
    /// Where a global revocation record is in its life cycle.
    enum GlobalRevocationRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global revocation record. Its code is unique within a tenant.
    final class GlobalRevocationRecord {
        var code: String
        var title: String
        var attributes: [String: String]
        var endsAt: Int
        var timezone: String
        var graceDays: Int
        var attempts: Int
        var checksum: String
        var active: Bool
        var status: GlobalRevocationRecordStatus

        init(code: String, title: String, attributes: [String: String], endsAt: Int, timezone: String, graceDays: Int, attempts: Int, checksum: String, active: Bool, status: GlobalRevocationRecordStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.endsAt = endsAt
            self.timezone = timezone
            self.graceDays = graceDays
            self.attempts = attempts
            self.checksum = checksum
            self.active = active
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

        func canMoveTo(_ next: GlobalRevocationRecordStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalRevocationRecordStatus.done || next == GlobalRevocationRecordStatus.failed
            case .queued:
                return next == GlobalRevocationRecordStatus.failed
            case .running:
                return next == GlobalRevocationRecordStatus.done
            case .done:
                return next == GlobalRevocationRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalRevocationRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global revocation record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func netTotal() -> Double {
            return (Double(attempts) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRevocationRecord {
            return GlobalRevocationRecord(
                code: code,
                title: title,
                attributes: attributes,
                endsAt: endsAt,
                timezone: timezone,
                graceDays: graceDays,
                attempts: attempts,
                checksum: checksum,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global revocation record in status new.
    static func newGlobalRevocationRecord(_ code: String, title: String) -> GlobalRevocationRecord {
        return GlobalRevocationRecord(
            code: code,
            title: title,
            attributes: [:],
            endsAt: 0,
            timezone: "",
            graceDays: 0,
            attempts: 0,
            checksum: "",
            active: false,
            status: GlobalRevocationRecordStatus.new
        )
    }
}
