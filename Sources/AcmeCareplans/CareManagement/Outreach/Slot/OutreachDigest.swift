import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach digest is in its life cycle.
    enum OutreachDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A outreach digest as the outreach team keeps it.
    final class OutreachDigest {
        var code: String
        var name: String
        var expiresAt: Int
        var checksum: String
        var allergy: String
        var batchSize: Int
        var active: Bool
        var payer: String
        var status: OutreachDigestStatus

        init(code: String, name: String, expiresAt: Int, checksum: String, allergy: String, batchSize: Int, active: Bool, payer: String, status: OutreachDigestStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.checksum = checksum
            self.allergy = allergy
            self.batchSize = batchSize
            self.active = active
            self.payer = payer
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

        func canMoveTo(_ next: OutreachDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == OutreachDigestStatus.failed
            case .queued:
                return next == OutreachDigestStatus.failed
            case .running:
                return next == OutreachDigestStatus.failed
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

        func moveTo(_ next: OutreachDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return ((Double(expiresAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachDigest {
            return OutreachDigest(
                code: code,
                name: name,
                expiresAt: expiresAt,
                checksum: checksum,
                allergy: allergy,
                batchSize: batchSize,
                active: active,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a outreach digest in status new.
    static func newOutreachDigest(_ code: String, name: String) -> OutreachDigest {
        return OutreachDigest(
            code: code,
            name: name,
            expiresAt: 0,
            checksum: "",
            allergy: "",
            batchSize: 0,
            active: false,
            payer: "",
            status: OutreachDigestStatus.new
        )
    }
}
