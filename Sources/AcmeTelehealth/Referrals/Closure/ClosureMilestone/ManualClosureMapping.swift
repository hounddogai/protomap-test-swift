import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual closure mapping is in its life cycle.
    enum ManualClosureMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual closure mapping as the closure team keeps it.
    final class ManualClosureMapping {
        var code: String
        var title: String
        var procedureCode: String
        var durationMinutes: Int
        var amount: Double
        var status: ManualClosureMappingStatus

        init(code: String, title: String, procedureCode: String, durationMinutes: Int, amount: Double, status: ManualClosureMappingStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.amount = amount
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

        func canMoveTo(_ next: ManualClosureMappingStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ManualClosureMappingStatus.draining
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

        func moveTo(_ next: ManualClosureMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual closure mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return ((Double(durationMinutes) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ManualClosureMapping {
            return ManualClosureMapping(
                code: code,
                title: title,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual closure mapping in status idle.
    static func newManualClosureMapping(_ code: String, title: String) -> ManualClosureMapping {
        return ManualClosureMapping(
            code: code,
            title: title,
            procedureCode: "",
            durationMinutes: 0,
            amount: 0.0,
            status: ManualClosureMappingStatus.idle
        )
    }
}
