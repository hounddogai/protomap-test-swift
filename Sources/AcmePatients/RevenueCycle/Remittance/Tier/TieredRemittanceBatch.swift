import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance batch is in its life cycle.
    enum TieredRemittanceBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered remittance batch. Its code is unique within a tenant.
    final class TieredRemittanceBatch {
        var code: String
        var name: String
        var bed: String
        var expiresAt: Int
        var specialty: String
        var reviewer: String
        var status: TieredRemittanceBatchStatus

        init(code: String, name: String, bed: String, expiresAt: Int, specialty: String, reviewer: String, status: TieredRemittanceBatchStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.expiresAt = expiresAt
            self.specialty = specialty
            self.reviewer = reviewer
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

        func canMoveTo(_ next: TieredRemittanceBatchStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredRemittanceBatchStatus.warming || next == TieredRemittanceBatchStatus.ready
            case .warming:
                return next == TieredRemittanceBatchStatus.draining || next == TieredRemittanceBatchStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TieredRemittanceBatchStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRemittanceBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> TieredRemittanceBatch {
            return TieredRemittanceBatch(
                code: code,
                name: name,
                bed: bed,
                expiresAt: expiresAt,
                specialty: specialty,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered remittance batch in status idle.
    static func newTieredRemittanceBatch(_ code: String, name: String) -> TieredRemittanceBatch {
        return TieredRemittanceBatch(
            code: code,
            name: name,
            bed: "",
            expiresAt: 0,
            specialty: "",
            reviewer: "",
            status: TieredRemittanceBatchStatus.idle
        )
    }
}
