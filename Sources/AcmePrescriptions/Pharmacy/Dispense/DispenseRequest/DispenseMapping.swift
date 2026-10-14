import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense mapping is in its life cycle.
    enum DispenseMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A dispense mapping as the dispense team keeps it.
    final class DispenseMapping {
        var code: String
        var name: String
        var threshold: Double
        var durationMinutes: Int
        var procedureCode: String
        var status: DispenseMappingStatus

        init(code: String, name: String, threshold: Double, durationMinutes: Int, procedureCode: String, status: DispenseMappingStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: DispenseMappingStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == DispenseMappingStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == DispenseMappingStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return ((Double(durationMinutes) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> DispenseMapping {
            return DispenseMapping(
                code: code,
                name: name,
                threshold: threshold,
                durationMinutes: durationMinutes,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a dispense mapping in status new.
    static func newDispenseMapping(_ code: String, name: String) -> DispenseMapping {
        return DispenseMapping(
            code: code,
            name: name,
            threshold: 0.0,
            durationMinutes: 0,
            procedureCode: "",
            status: DispenseMappingStatus.new
        )
    }
}
