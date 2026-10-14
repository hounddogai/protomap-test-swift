import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program forecast is in its life cycle.
    enum ProgramForecastStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a program forecast and its current status.
    final class ProgramForecast {
        var code: String
        var title: String
        var batchSize: Int
        var priority: Int
        var name: String
        var discount: Double
        var pinned: Bool
        var graceDays: Int
        var revision: Int
        var bed: String
        var status: ProgramForecastStatus

        init(code: String, title: String, batchSize: Int, priority: Int, name: String, discount: Double, pinned: Bool, graceDays: Int, revision: Int, bed: String, status: ProgramForecastStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.priority = priority
            self.name = name
            self.discount = discount
            self.pinned = pinned
            self.graceDays = graceDays
            self.revision = revision
            self.bed = bed
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

        func canMoveTo(_ next: ProgramForecastStatus) -> Bool {
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
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ProgramForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramForecast {
            return ProgramForecast(
                code: code,
                title: title,
                batchSize: batchSize,
                priority: priority,
                name: name,
                discount: discount,
                pinned: pinned,
                graceDays: graceDays,
                revision: revision,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a program forecast in status new.
    static func newProgramForecast(_ code: String, title: String) -> ProgramForecast {
        return ProgramForecast(
            code: code,
            title: title,
            batchSize: 0,
            priority: 0,
            name: "",
            discount: 0.0,
            pinned: false,
            graceDays: 0,
            revision: 0,
            bed: "",
            status: ProgramForecastStatus.new
        )
    }
}
