import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive read group is in its life cycle.
    enum AdaptiveReadGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive read group as the read team keeps it.
    final class AdaptiveReadGroup {
        var code: String
        var name: String
        var approved: Bool
        var unit: String
        var margin: Double
        var ownerID: String
        var startsAt: Int
        var budget: Double
        var visible: Bool
        var batchSize: Int
        var status: AdaptiveReadGroupStatus

        init(code: String, name: String, approved: Bool, unit: String, margin: Double, ownerID: String, startsAt: Int, budget: Double, visible: Bool, batchSize: Int, status: AdaptiveReadGroupStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.unit = unit
            self.margin = margin
            self.ownerID = ownerID
            self.startsAt = startsAt
            self.budget = budget
            self.visible = visible
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveReadGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AdaptiveReadGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive read group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive read group") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((budget + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveReadGroup {
            return AdaptiveReadGroup(
                code: code,
                name: name,
                approved: approved,
                unit: unit,
                margin: margin,
                ownerID: ownerID,
                startsAt: startsAt,
                budget: budget,
                visible: visible,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive read group in status requested.
    static func newAdaptiveReadGroup(_ code: String, name: String) -> AdaptiveReadGroup {
        return AdaptiveReadGroup(
            code: code,
            name: name,
            approved: false,
            unit: "",
            margin: 0.0,
            ownerID: "",
            startsAt: 0,
            budget: 0.0,
            visible: false,
            batchSize: 0,
            status: AdaptiveReadGroupStatus.requested
        )
    }
}
