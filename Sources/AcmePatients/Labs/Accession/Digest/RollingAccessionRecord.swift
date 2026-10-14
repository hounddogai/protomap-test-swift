import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling accession record is in its life cycle.
    enum RollingAccessionRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a rolling accession record and its current status.
    final class RollingAccessionRecord {
        var code: String
        var name: String
        var batchSize: Int
        var quantity: Int
        var tags: [String]
        var approved: Bool
        var budget: Double
        var endsAt: Int
        var score: Double
        var region: String
        var status: RollingAccessionRecordStatus

        init(code: String, name: String, batchSize: Int, quantity: Int, tags: [String], approved: Bool, budget: Double, endsAt: Int, score: Double, region: String, status: RollingAccessionRecordStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.quantity = quantity
            self.tags = tags
            self.approved = approved
            self.budget = budget
            self.endsAt = endsAt
            self.score = score
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingAccessionRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingAccessionRecordStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RollingAccessionRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAccessionRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling accession record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return ((score - budget) * 100).rounded() / 100
        }

        func copyValue() -> RollingAccessionRecord {
            return RollingAccessionRecord(
                code: code,
                name: name,
                batchSize: batchSize,
                quantity: quantity,
                tags: tags,
                approved: approved,
                budget: budget,
                endsAt: endsAt,
                score: score,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling accession record in status proposed.
    static func newRollingAccessionRecord(_ code: String, name: String) -> RollingAccessionRecord {
        return RollingAccessionRecord(
            code: code,
            name: name,
            batchSize: 0,
            quantity: 0,
            tags: [],
            approved: false,
            budget: 0.0,
            endsAt: 0,
            score: 0.0,
            region: "",
            status: RollingAccessionRecordStatus.proposed
        )
    }
}
