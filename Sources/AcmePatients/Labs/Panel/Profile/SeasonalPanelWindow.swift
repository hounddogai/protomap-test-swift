import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal panel window is in its life cycle.
    enum SeasonalPanelWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal panel window and its current status.
    final class SeasonalPanelWindow {
        var code: String
        var name: String
        var margin: Double
        var version: Int
        var ownerID: String
        var startsAt: Int
        var ratio: Double
        var limit: Int
        var status: SeasonalPanelWindowStatus

        init(code: String, name: String, margin: Double, version: Int, ownerID: String, startsAt: Int, ratio: Double, limit: Int, status: SeasonalPanelWindowStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.version = version
            self.ownerID = ownerID
            self.startsAt = startsAt
            self.ratio = ratio
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalPanelWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalPanelWindowStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalPanelWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalPanelWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal panel window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((Double(limit) + margin) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPanelWindow {
            return SeasonalPanelWindow(
                code: code,
                name: name,
                margin: margin,
                version: version,
                ownerID: ownerID,
                startsAt: startsAt,
                ratio: ratio,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal panel window in status new.
    static func newSeasonalPanelWindow(_ code: String, name: String) -> SeasonalPanelWindow {
        return SeasonalPanelWindow(
            code: code,
            name: name,
            margin: 0.0,
            version: 0,
            ownerID: "",
            startsAt: 0,
            ratio: 0.0,
            limit: 0,
            status: SeasonalPanelWindowStatus.new
        )
    }
}
