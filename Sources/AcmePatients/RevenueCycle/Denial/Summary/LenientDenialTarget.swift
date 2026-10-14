import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient denial target is in its life cycle.
    enum LenientDenialTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient denial target, with what the planners need to act on it.
    final class LenientDenialTarget {
        var code: String
        var label: String
        var budget: Double
        var createdAt: Int
        var unit: String
        var segment: String
        var expiresAt: Int
        var limit: Int
        var visible: Bool
        var status: LenientDenialTargetStatus

        init(code: String, label: String, budget: Double, createdAt: Int, unit: String, segment: String, expiresAt: Int, limit: Int, visible: Bool, status: LenientDenialTargetStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.createdAt = createdAt
            self.unit = unit
            self.segment = segment
            self.expiresAt = expiresAt
            self.limit = limit
            self.visible = visible
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

        func canMoveTo(_ next: LenientDenialTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LenientDenialTargetStatus.ready || next == LenientDenialTargetStatus.draining
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

        func moveTo(_ next: LenientDenialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient denial target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient denial target") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(limit) * budget * 100).rounded() / 100
        }

        func copyValue() -> LenientDenialTarget {
            return LenientDenialTarget(
                code: code,
                label: label,
                budget: budget,
                createdAt: createdAt,
                unit: unit,
                segment: segment,
                expiresAt: expiresAt,
                limit: limit,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient denial target in status idle.
    static func newLenientDenialTarget(_ code: String, label: String) -> LenientDenialTarget {
        return LenientDenialTarget(
            code: code,
            label: label,
            budget: 0.0,
            createdAt: 0,
            unit: "",
            segment: "",
            expiresAt: 0,
            limit: 0,
            visible: false,
            status: LenientDenialTargetStatus.idle
        )
    }
}
