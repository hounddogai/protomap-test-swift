import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global inventory threshold is in its life cycle.
    enum GlobalInventoryThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global inventory threshold, with what the planners need to act on it.
    final class GlobalInventoryThreshold {
        var code: String
        var name: String
        var region: String
        var graceDays: Int
        var procedureCode: String
        var source: String
        var title: String
        var status: GlobalInventoryThresholdStatus

        init(code: String, name: String, region: String, graceDays: Int, procedureCode: String, source: String, title: String, status: GlobalInventoryThresholdStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.source = source
            self.title = title
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

        func canMoveTo(_ next: GlobalInventoryThresholdStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalInventoryThresholdStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalInventoryThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global inventory threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global inventory threshold") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> GlobalInventoryThreshold {
            return GlobalInventoryThreshold(
                code: code,
                name: name,
                region: region,
                graceDays: graceDays,
                procedureCode: procedureCode,
                source: source,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global inventory threshold in status idle.
    static func newGlobalInventoryThreshold(_ code: String, name: String) -> GlobalInventoryThreshold {
        return GlobalInventoryThreshold(
            code: code,
            name: name,
            region: "",
            graceDays: 0,
            procedureCode: "",
            source: "",
            title: "",
            status: GlobalInventoryThresholdStatus.idle
        )
    }
}
