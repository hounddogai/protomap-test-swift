import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending denial ledger is in its life cycle.
    enum PendingDenialLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending denial ledger as the denial team keeps it.
    final class PendingDenialLedger {
        var code: String
        var title: String
        var allergy: String
        var sequence: Int
        var threshold: Double
        var category: String
        var ownerID: String
        var expiresAt: Int
        var description: String
        var floorValue: Double
        var status: PendingDenialLedgerStatus

        init(code: String, title: String, allergy: String, sequence: Int, threshold: Double, category: String, ownerID: String, expiresAt: Int, description: String, floorValue: Double, status: PendingDenialLedgerStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.sequence = sequence
            self.threshold = threshold
            self.category = category
            self.ownerID = ownerID
            self.expiresAt = expiresAt
            self.description = description
            self.floorValue = floorValue
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

        func canMoveTo(_ next: PendingDenialLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingDenialLedgerStatus.ready || next == PendingDenialLedgerStatus.draining
            case .ready:
                return next == PendingDenialLedgerStatus.draining || next == PendingDenialLedgerStatus.stopped
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

        func moveTo(_ next: PendingDenialLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending denial ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netVolume() -> Double {
            return ((Double(sequence) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingDenialLedger {
            return PendingDenialLedger(
                code: code,
                title: title,
                allergy: allergy,
                sequence: sequence,
                threshold: threshold,
                category: category,
                ownerID: ownerID,
                expiresAt: expiresAt,
                description: description,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending denial ledger in status idle.
    static func newPendingDenialLedger(_ code: String, title: String) -> PendingDenialLedger {
        return PendingDenialLedger(
            code: code,
            title: title,
            allergy: "",
            sequence: 0,
            threshold: 0.0,
            category: "",
            ownerID: "",
            expiresAt: 0,
            description: "",
            floorValue: 0.0,
            status: PendingDenialLedgerStatus.idle
        )
    }
}
