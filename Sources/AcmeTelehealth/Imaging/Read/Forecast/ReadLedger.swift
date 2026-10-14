import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read ledger is in its life cycle.
    enum ReadLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A read ledger. Its code is unique within a tenant.
    final class ReadLedger {
        var code: String
        var title: String
        var active: Bool
        var ownerID: String
        var refills: Int
        var expiresAt: Int
        var version: Int
        var encounterID: String
        var status: ReadLedgerStatus

        init(code: String, title: String, active: Bool, ownerID: String, refills: Int, expiresAt: Int, version: Int, encounterID: String, status: ReadLedgerStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.ownerID = ownerID
            self.refills = refills
            self.expiresAt = expiresAt
            self.version = version
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ReadLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ReadLedgerStatus.done || next == ReadLedgerStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReadLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netExposure() -> Double {
            return ((Double(expiresAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ReadLedger {
            return ReadLedger(
                code: code,
                title: title,
                active: active,
                ownerID: ownerID,
                refills: refills,
                expiresAt: expiresAt,
                version: version,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a read ledger in status new.
    static func newReadLedger(_ code: String, title: String) -> ReadLedger {
        return ReadLedger(
            code: code,
            title: title,
            active: false,
            ownerID: "",
            refills: 0,
            expiresAt: 0,
            version: 0,
            encounterID: "",
            status: ReadLedgerStatus.new
        )
    }
}
