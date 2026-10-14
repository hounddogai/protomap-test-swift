import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range ledger is in its life cycle.
    enum ReferenceRangeLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A reference range ledger. Its code is unique within a tenant.
    final class ReferenceRangeLedger {
        var code: String
        var name: String
        var revision: Int
        var region: String
        var updatedAt: Int
        var notes: String
        var score: Double
        var weight: Double
        var limit: Int
        var status: ReferenceRangeLedgerStatus

        init(code: String, name: String, revision: Int, region: String, updatedAt: Int, notes: String, score: Double, weight: Double, limit: Int, status: ReferenceRangeLedgerStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.region = region
            self.updatedAt = updatedAt
            self.notes = notes
            self.score = score
            self.weight = weight
            self.limit = limit
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

        func canMoveTo(_ next: ReferenceRangeLedgerStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReferenceRangeLedgerStatus.warming || next == ReferenceRangeLedgerStatus.draining
            case .warming:
                return next == ReferenceRangeLedgerStatus.ready || next == ReferenceRangeLedgerStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ReferenceRangeLedgerStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return (weight * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeLedger {
            return ReferenceRangeLedger(
                code: code,
                name: name,
                revision: revision,
                region: region,
                updatedAt: updatedAt,
                notes: notes,
                score: score,
                weight: weight,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a reference range ledger in status idle.
    static func newReferenceRangeLedger(_ code: String, name: String) -> ReferenceRangeLedger {
        return ReferenceRangeLedger(
            code: code,
            name: name,
            revision: 0,
            region: "",
            updatedAt: 0,
            notes: "",
            score: 0.0,
            weight: 0.0,
            limit: 0,
            status: ReferenceRangeLedgerStatus.idle
        )
    }
}
