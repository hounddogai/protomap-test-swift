import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim record is in its life cycle.
    enum ClaimRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A claim record as the claim team keeps it.
    final class ClaimRecord {
        var code: String
        var name: String
        var limit: Int
        var category: String
        var startsAt: Int
        var ratio: Double
        var payer: String
        var expiresAt: Int
        var status: ClaimRecordStatus

        init(code: String, name: String, limit: Int, category: String, startsAt: Int, ratio: Double, payer: String, expiresAt: Int, status: ClaimRecordStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.category = category
            self.startsAt = startsAt
            self.ratio = ratio
            self.payer = payer
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: ClaimRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ClaimRecordStatus.ready || next == ClaimRecordStatus.stopped
            case .ready:
                return next == ClaimRecordStatus.draining || next == ClaimRecordStatus.stopped
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

        func moveTo(_ next: ClaimRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("claim record") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(limit) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimRecord {
            return ClaimRecord(
                code: code,
                name: name,
                limit: limit,
                category: category,
                startsAt: startsAt,
                ratio: ratio,
                payer: payer,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a claim record in status idle.
    static func newClaimRecord(_ code: String, name: String) -> ClaimRecord {
        return ClaimRecord(
            code: code,
            name: name,
            limit: 0,
            category: "",
            startsAt: 0,
            ratio: 0.0,
            payer: "",
            expiresAt: 0,
            status: ClaimRecordStatus.idle
        )
    }
}
