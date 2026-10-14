import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim window is in its life cycle.
    enum ClaimWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a claim window and its current status.
    final class ClaimWindow {
        var code: String
        var name: String
        var limit: Int
        var windowDays: Int
        var score: Double
        var quantity: Int
        var status: ClaimWindowStatus

        init(code: String, name: String, limit: Int, windowDays: Int, score: Double, quantity: Int, status: ClaimWindowStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.windowDays = windowDays
            self.score = score
            self.quantity = quantity
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

        func canMoveTo(_ next: ClaimWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
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
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ClaimWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(quantity) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimWindow {
            return ClaimWindow(
                code: code,
                name: name,
                limit: limit,
                windowDays: windowDays,
                score: score,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim window in status new.
    static func newClaimWindow(_ code: String, name: String) -> ClaimWindow {
        return ClaimWindow(
            code: code,
            name: name,
            limit: 0,
            windowDays: 0,
            score: 0.0,
            quantity: 0,
            status: ClaimWindowStatus.new
        )
    }
}
