import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional dispense estimate is in its life cycle.
    enum RegionalDispenseEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional dispense estimate and its current status.
    final class RegionalDispenseEstimate {
        var code: String
        var name: String
        var durationMinutes: Int
        var expiresAt: Int
        var quantity: Int
        var unit: String
        var capacity: Int
        var score: Double
        var tags: [String]
        var acuity: Int
        var status: RegionalDispenseEstimateStatus

        init(code: String, name: String, durationMinutes: Int, expiresAt: Int, quantity: Int, unit: String, capacity: Int, score: Double, tags: [String], acuity: Int, status: RegionalDispenseEstimateStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.unit = unit
            self.capacity = capacity
            self.score = score
            self.tags = tags
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalDispenseEstimateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalDispenseEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalDispenseEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional dispense estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
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

        func weightedVolume() -> Double {
            return ((score + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDispenseEstimate {
            return RegionalDispenseEstimate(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                quantity: quantity,
                unit: unit,
                capacity: capacity,
                score: score,
                tags: tags,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional dispense estimate in status planned.
    static func newRegionalDispenseEstimate(_ code: String, name: String) -> RegionalDispenseEstimate {
        return RegionalDispenseEstimate(
            code: code,
            name: name,
            durationMinutes: 0,
            expiresAt: 0,
            quantity: 0,
            unit: "",
            capacity: 0,
            score: 0.0,
            tags: [],
            acuity: 0,
            status: RegionalDispenseEstimateStatus.planned
        )
    }
}
