import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol forecast is in its life cycle.
    enum CareProtocolForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A care protocol forecast as the care protocol team keeps it.
    final class CareProtocolForecast {
        var code: String
        var name: String
        var score: Double
        var visible: Bool
        var title: String
        var floorValue: Double
        var procedureCode: String
        var createdAt: Int
        var status: CareProtocolForecastStatus

        init(code: String, name: String, score: Double, visible: Bool, title: String, floorValue: Double, procedureCode: String, createdAt: Int, status: CareProtocolForecastStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.visible = visible
            self.title = title
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.createdAt = createdAt
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

        func canMoveTo(_ next: CareProtocolForecastStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: CareProtocolForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("care protocol forecast") \(code)"
        }

        func effectiveVolume() -> Double {
            return (Double(createdAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolForecast {
            return CareProtocolForecast(
                code: code,
                name: name,
                score: score,
                visible: visible,
                title: title,
                floorValue: floorValue,
                procedureCode: procedureCode,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol forecast in status created.
    static func newCareProtocolForecast(_ code: String, name: String) -> CareProtocolForecast {
        return CareProtocolForecast(
            code: code,
            name: name,
            score: 0.0,
            visible: false,
            title: "",
            floorValue: 0.0,
            procedureCode: "",
            createdAt: 0,
            status: CareProtocolForecastStatus.created
        )
    }
}
