import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped modality window is in its life cycle.
    enum CappedModalityWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped modality window. Its code is unique within a tenant.
    final class CappedModalityWindow {
        var code: String
        var name: String
        var region: String
        var dosageMg: Double
        var facility: String
        var status: CappedModalityWindowStatus

        init(code: String, name: String, region: String, dosageMg: Double, facility: String, status: CappedModalityWindowStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.dosageMg = dosageMg
            self.facility = facility
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

        func canMoveTo(_ next: CappedModalityWindowStatus) -> Bool {
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
                return next == CappedModalityWindowStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CappedModalityWindowStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedModalityWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped modality window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> CappedModalityWindow {
            return CappedModalityWindow(
                code: code,
                name: name,
                region: region,
                dosageMg: dosageMg,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped modality window in status idle.
    static func newCappedModalityWindow(_ code: String, name: String) -> CappedModalityWindow {
        return CappedModalityWindow(
            code: code,
            name: name,
            region: "",
            dosageMg: 0.0,
            facility: "",
            status: CappedModalityWindowStatus.idle
        )
    }
}
