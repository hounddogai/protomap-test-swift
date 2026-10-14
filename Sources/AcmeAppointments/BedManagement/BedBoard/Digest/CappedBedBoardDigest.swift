import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped bed board digest is in its life cycle.
    enum CappedBedBoardDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a capped bed board digest and its current status.
    final class CappedBedBoardDigest {
        var code: String
        var name: String
        var score: Double
        var budget: Double
        var quantity: Int
        var batchSize: Int
        var amount: Double
        var weight: Double
        var segment: String
        var version: Int
        var startsAt: Int
        var status: CappedBedBoardDigestStatus

        init(code: String, name: String, score: Double, budget: Double, quantity: Int, batchSize: Int, amount: Double, weight: Double, segment: String, version: Int, startsAt: Int, status: CappedBedBoardDigestStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.budget = budget
            self.quantity = quantity
            self.batchSize = batchSize
            self.amount = amount
            self.weight = weight
            self.segment = segment
            self.version = version
            self.startsAt = startsAt
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

        func canMoveTo(_ next: CappedBedBoardDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedBedBoardDigestStatus.draining
            case .warming:
                return next == CappedBedBoardDigestStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedBedBoardDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped bed board digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("capped bed board digest") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(version) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CappedBedBoardDigest {
            return CappedBedBoardDigest(
                code: code,
                name: name,
                score: score,
                budget: budget,
                quantity: quantity,
                batchSize: batchSize,
                amount: amount,
                weight: weight,
                segment: segment,
                version: version,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped bed board digest in status idle.
    static func newCappedBedBoardDigest(_ code: String, name: String) -> CappedBedBoardDigest {
        return CappedBedBoardDigest(
            code: code,
            name: name,
            score: 0.0,
            budget: 0.0,
            quantity: 0,
            batchSize: 0,
            amount: 0.0,
            weight: 0.0,
            segment: "",
            version: 0,
            startsAt: 0,
            status: CappedBedBoardDigestStatus.idle
        )
    }
}
