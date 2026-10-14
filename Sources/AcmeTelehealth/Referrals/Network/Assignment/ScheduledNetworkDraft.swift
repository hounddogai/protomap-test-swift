import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled network draft is in its life cycle.
    enum ScheduledNetworkDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled network draft as the network team keeps it.
    final class ScheduledNetworkDraft {
        var code: String
        var name: String
        var windowDays: Int
        var endsAt: Int
        var acuity: Int
        var status: ScheduledNetworkDraftStatus

        init(code: String, name: String, windowDays: Int, endsAt: Int, acuity: Int, status: ScheduledNetworkDraftStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.endsAt = endsAt
            self.acuity = acuity
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

        func canMoveTo(_ next: ScheduledNetworkDraftStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ScheduledNetworkDraftStatus.running || next == ScheduledNetworkDraftStatus.done
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledNetworkDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled network draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return (Double(windowDays) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledNetworkDraft {
            return ScheduledNetworkDraft(
                code: code,
                name: name,
                windowDays: windowDays,
                endsAt: endsAt,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled network draft in status new.
    static func newScheduledNetworkDraft(_ code: String, name: String) -> ScheduledNetworkDraft {
        return ScheduledNetworkDraft(
            code: code,
            name: name,
            windowDays: 0,
            endsAt: 0,
            acuity: 0,
            status: ScheduledNetworkDraftStatus.new
        )
    }
}
