import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal read estimate is in its life cycle.
    enum SeasonalReadEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal read estimate and its current status.
    final class SeasonalReadEstimate {
        var code: String
        var title: String
        var ownerID: String
        var updatedAt: Int
        var ceiling: Double
        var payer: String
        var expiresAt: Int
        var floorValue: Double
        var retries: Int
        var status: SeasonalReadEstimateStatus

        init(code: String, title: String, ownerID: String, updatedAt: Int, ceiling: Double, payer: String, expiresAt: Int, floorValue: Double, retries: Int, status: SeasonalReadEstimateStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.payer = payer
            self.expiresAt = expiresAt
            self.floorValue = floorValue
            self.retries = retries
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

        func canMoveTo(_ next: SeasonalReadEstimateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalReadEstimateStatus.running || next == SeasonalReadEstimateStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: SeasonalReadEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal read estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal read estimate") \(code)"
        }

        func weightedValue() -> Double {
            return ((floorValue - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalReadEstimate {
            return SeasonalReadEstimate(
                code: code,
                title: title,
                ownerID: ownerID,
                updatedAt: updatedAt,
                ceiling: ceiling,
                payer: payer,
                expiresAt: expiresAt,
                floorValue: floorValue,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal read estimate in status new.
    static func newSeasonalReadEstimate(_ code: String, title: String) -> SeasonalReadEstimate {
        return SeasonalReadEstimate(
            code: code,
            title: title,
            ownerID: "",
            updatedAt: 0,
            ceiling: 0.0,
            payer: "",
            expiresAt: 0,
            floorValue: 0.0,
            retries: 0,
            status: SeasonalReadEstimateStatus.new
        )
    }
}
