import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary shift forecast is in its life cycle.
    enum PrimaryShiftForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary shift forecast as the shift team keeps it.
    final class PrimaryShiftForecast {
        var code: String
        var label: String
        var procedureCode: String
        var createdAt: Int
        var archived: Bool
        var status: PrimaryShiftForecastStatus

        init(code: String, label: String, procedureCode: String, createdAt: Int, archived: Bool, status: PrimaryShiftForecastStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.createdAt = createdAt
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryShiftForecastStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimaryShiftForecastStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryShiftForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary shift forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("primary shift forecast") \(code)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> PrimaryShiftForecast {
            return PrimaryShiftForecast(
                code: code,
                label: label,
                procedureCode: procedureCode,
                createdAt: createdAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary shift forecast in status idle.
    static func newPrimaryShiftForecast(_ code: String, label: String) -> PrimaryShiftForecast {
        return PrimaryShiftForecast(
            code: code,
            label: label,
            procedureCode: "",
            createdAt: 0,
            archived: false,
            status: PrimaryShiftForecastStatus.idle
        )
    }
}
