import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal order set window is in its life cycle.
    enum SeasonalOrderSetWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One seasonal order set window, with what the planners need to act on it.
    final class SeasonalOrderSetWindow {
        var code: String
        var name: String
        var margin: Double
        var active: Bool
        var batchSize: Int
        var ceiling: Double
        var retries: Int
        var specialty: String
        var status: SeasonalOrderSetWindowStatus

        init(code: String, name: String, margin: Double, active: Bool, batchSize: Int, ceiling: Double, retries: Int, specialty: String, status: SeasonalOrderSetWindowStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.active = active
            self.batchSize = batchSize
            self.ceiling = ceiling
            self.retries = retries
            self.specialty = specialty
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

        func canMoveTo(_ next: SeasonalOrderSetWindowStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalOrderSetWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal order set window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return (Double(batchSize) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> SeasonalOrderSetWindow {
            return SeasonalOrderSetWindow(
                code: code,
                name: name,
                margin: margin,
                active: active,
                batchSize: batchSize,
                ceiling: ceiling,
                retries: retries,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal order set window in status draft.
    static func newSeasonalOrderSetWindow(_ code: String, name: String) -> SeasonalOrderSetWindow {
        return SeasonalOrderSetWindow(
            code: code,
            name: name,
            margin: 0.0,
            active: false,
            batchSize: 0,
            ceiling: 0.0,
            retries: 0,
            specialty: "",
            status: SeasonalOrderSetWindowStatus.draft
        )
    }
}
