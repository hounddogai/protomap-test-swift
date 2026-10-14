import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool target is in its life cycle.
    enum FloatPoolTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a float pool target and its current status.
    final class FloatPoolTarget {
        var code: String
        var name: String
        var summary: String
        var durationMinutes: Int
        var capacity: Int
        var refills: Int
        var ratio: Double
        var version: Int
        var amount: Double
        var quantity: Int
        var status: FloatPoolTargetStatus

        init(code: String, name: String, summary: String, durationMinutes: Int, capacity: Int, refills: Int, ratio: Double, version: Int, amount: Double, quantity: Int, status: FloatPoolTargetStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.durationMinutes = durationMinutes
            self.capacity = capacity
            self.refills = refills
            self.ratio = ratio
            self.version = version
            self.amount = amount
            self.quantity = quantity
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

        func canMoveTo(_ next: FloatPoolTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == FloatPoolTargetStatus.ready || next == FloatPoolTargetStatus.draining
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FloatPoolTargetStatus.draining || next == FloatPoolTargetStatus.stopped
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

        func moveTo(_ next: FloatPoolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return ((Double(capacity) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolTarget {
            return FloatPoolTarget(
                code: code,
                name: name,
                summary: summary,
                durationMinutes: durationMinutes,
                capacity: capacity,
                refills: refills,
                ratio: ratio,
                version: version,
                amount: amount,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a float pool target in status idle.
    static func newFloatPoolTarget(_ code: String, name: String) -> FloatPoolTarget {
        return FloatPoolTarget(
            code: code,
            name: name,
            summary: "",
            durationMinutes: 0,
            capacity: 0,
            refills: 0,
            ratio: 0.0,
            version: 0,
            amount: 0.0,
            quantity: 0,
            status: FloatPoolTargetStatus.idle
        )
    }
}
