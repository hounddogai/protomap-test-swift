import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network baseline is in its life cycle.
    enum NetworkBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a network baseline and its current status.
    final class NetworkBaseline {
        var code: String
        var label: String
        var notes: String
        var floorValue: Double
        var unit: String
        var limit: Int
        var startsAt: Int
        var cost: Double
        var maximum: Double
        var status: NetworkBaselineStatus

        init(code: String, label: String, notes: String, floorValue: Double, unit: String, limit: Int, startsAt: Int, cost: Double, maximum: Double, status: NetworkBaselineStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.floorValue = floorValue
            self.unit = unit
            self.limit = limit
            self.startsAt = startsAt
            self.cost = cost
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == NetworkBaselineStatus.pending
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == NetworkBaselineStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: NetworkBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return ((floorValue + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkBaseline {
            return NetworkBaseline(
                code: code,
                label: label,
                notes: notes,
                floorValue: floorValue,
                unit: unit,
                limit: limit,
                startsAt: startsAt,
                cost: cost,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a network baseline in status draft.
    static func newNetworkBaseline(_ code: String, label: String) -> NetworkBaseline {
        return NetworkBaseline(
            code: code,
            label: label,
            notes: "",
            floorValue: 0.0,
            unit: "",
            limit: 0,
            startsAt: 0,
            cost: 0.0,
            maximum: 0.0,
            status: NetworkBaselineStatus.draft
        )
    }
}
