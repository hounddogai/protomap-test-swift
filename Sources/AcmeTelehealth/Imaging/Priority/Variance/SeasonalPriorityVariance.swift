import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal priority variance is in its life cycle.
    enum SeasonalPriorityVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal priority variance as the priority team keeps it.
    final class SeasonalPriorityVariance {
        var code: String
        var title: String
        var copay: Double
        var dosageMg: Double
        var updatedAt: Int
        var ceiling: Double
        var channel: String
        var retries: Int
        var description: String
        var country: String
        var status: SeasonalPriorityVarianceStatus

        init(code: String, title: String, copay: Double, dosageMg: Double, updatedAt: Int, ceiling: Double, channel: String, retries: Int, description: String, country: String, status: SeasonalPriorityVarianceStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.dosageMg = dosageMg
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.channel = channel
            self.retries = retries
            self.description = description
            self.country = country
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

        func canMoveTo(_ next: SeasonalPriorityVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalPriorityVarianceStatus.failed
            case .queued:
                return next == SeasonalPriorityVarianceStatus.running || next == SeasonalPriorityVarianceStatus.failed
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: SeasonalPriorityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal priority variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal priority variance") \(code)"
        }

        func weightedExposure() -> Double {
            return (Double(retries) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPriorityVariance {
            return SeasonalPriorityVariance(
                code: code,
                title: title,
                copay: copay,
                dosageMg: dosageMg,
                updatedAt: updatedAt,
                ceiling: ceiling,
                channel: channel,
                retries: retries,
                description: description,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a seasonal priority variance in status new.
    static func newSeasonalPriorityVariance(_ code: String, title: String) -> SeasonalPriorityVariance {
        return SeasonalPriorityVariance(
            code: code,
            title: title,
            copay: 0.0,
            dosageMg: 0.0,
            updatedAt: 0,
            ceiling: 0.0,
            channel: "",
            retries: 0,
            description: "",
            country: "",
            status: SeasonalPriorityVarianceStatus.new
        )
    }
}
