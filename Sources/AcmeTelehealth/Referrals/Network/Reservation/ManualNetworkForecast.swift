import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network forecast is in its life cycle.
    enum ManualNetworkForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a manual network forecast and its current status.
    final class ManualNetworkForecast {
        var code: String
        var name: String
        var durationMinutes: Int
        var archived: Bool
        var category: String
        var ratio: Double
        var minimum: Double
        var checksum: String
        var procedureCode: String
        var status: ManualNetworkForecastStatus

        init(code: String, name: String, durationMinutes: Int, archived: Bool, category: String, ratio: Double, minimum: Double, checksum: String, procedureCode: String, status: ManualNetworkForecastStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.archived = archived
            self.category = category
            self.ratio = ratio
            self.minimum = minimum
            self.checksum = checksum
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualNetworkForecastStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ManualNetworkForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual network forecast") \(code)"
        }

        func weightedExposure() -> Double {
            return (minimum * ratio * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkForecast {
            return ManualNetworkForecast(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                archived: archived,
                category: category,
                ratio: ratio,
                minimum: minimum,
                checksum: checksum,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual network forecast in status created.
    static func newManualNetworkForecast(_ code: String, name: String) -> ManualNetworkForecast {
        return ManualNetworkForecast(
            code: code,
            name: name,
            durationMinutes: 0,
            archived: false,
            category: "",
            ratio: 0.0,
            minimum: 0.0,
            checksum: "",
            procedureCode: "",
            status: ManualNetworkForecastStatus.created
        )
    }
}
