import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback inventory score is in its life cycle.
    enum FallbackInventoryScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback inventory score as the inventory team keeps it.
    final class FallbackInventoryScore {
        var code: String
        var name: String
        var weight: Double
        var batchSize: Int
        var visitMinutes: Int
        var bed: String
        var startsAt: Int
        var notes: String
        var status: FallbackInventoryScoreStatus

        init(code: String, name: String, weight: Double, batchSize: Int, visitMinutes: Int, bed: String, startsAt: Int, notes: String, status: FallbackInventoryScoreStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.batchSize = batchSize
            self.visitMinutes = visitMinutes
            self.bed = bed
            self.startsAt = startsAt
            self.notes = notes
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

        func canMoveTo(_ next: FallbackInventoryScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FallbackInventoryScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback inventory score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return (weight * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> FallbackInventoryScore {
            return FallbackInventoryScore(
                code: code,
                name: name,
                weight: weight,
                batchSize: batchSize,
                visitMinutes: visitMinutes,
                bed: bed,
                startsAt: startsAt,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback inventory score in status proposed.
    static func newFallbackInventoryScore(_ code: String, name: String) -> FallbackInventoryScore {
        return FallbackInventoryScore(
            code: code,
            name: name,
            weight: 0.0,
            batchSize: 0,
            visitMinutes: 0,
            bed: "",
            startsAt: 0,
            notes: "",
            status: FallbackInventoryScoreStatus.proposed
        )
    }
}
