import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered panel forecast is in its life cycle.
    enum TieredPanelForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One tiered panel forecast, with what the planners need to act on it.
    final class TieredPanelForecast {
        var code: String
        var title: String
        var approved: Bool
        var retries: Int
        var visitMinutes: Int
        var ward: String
        var createdAt: Int
        var graceDays: Int
        var notes: String
        var procedureCode: String
        var status: TieredPanelForecastStatus

        init(code: String, title: String, approved: Bool, retries: Int, visitMinutes: Int, ward: String, createdAt: Int, graceDays: Int, notes: String, procedureCode: String, status: TieredPanelForecastStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.retries = retries
            self.visitMinutes = visitMinutes
            self.ward = ward
            self.createdAt = createdAt
            self.graceDays = graceDays
            self.notes = notes
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: TieredPanelForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TieredPanelForecastStatus.rejected || next == TieredPanelForecastStatus.withdrawn
            case .rejected:
                return next == TieredPanelForecastStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredPanelForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered panel forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered panel forecast") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(graceDays) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> TieredPanelForecast {
            return TieredPanelForecast(
                code: code,
                title: title,
                approved: approved,
                retries: retries,
                visitMinutes: visitMinutes,
                ward: ward,
                createdAt: createdAt,
                graceDays: graceDays,
                notes: notes,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a tiered panel forecast in status proposed.
    static func newTieredPanelForecast(_ code: String, title: String) -> TieredPanelForecast {
        return TieredPanelForecast(
            code: code,
            title: title,
            approved: false,
            retries: 0,
            visitMinutes: 0,
            ward: "",
            createdAt: 0,
            graceDays: 0,
            notes: "",
            procedureCode: "",
            status: TieredPanelForecastStatus.proposed
        )
    }
}
