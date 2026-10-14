import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary recall profile is in its life cycle.
    enum PrimaryRecallProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary recall profile. Its code is unique within a tenant.
    final class PrimaryRecallProfile {
        var code: String
        var name: String
        var visitMinutes: Int
        var copay: Double
        var reviewer: String
        var status: PrimaryRecallProfileStatus

        init(code: String, name: String, visitMinutes: Int, copay: Double, reviewer: String, status: PrimaryRecallProfileStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.reviewer = reviewer
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

        func canMoveTo(_ next: PrimaryRecallProfileStatus) -> Bool {
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
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PrimaryRecallProfileStatus.draining
            case .draining:
                return next == PrimaryRecallProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryRecallProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary recall profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary recall profile") \(code)"
        }

        func weightedExposure() -> Double {
            return ((copay + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRecallProfile {
            return PrimaryRecallProfile(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                copay: copay,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary recall profile in status idle.
    static func newPrimaryRecallProfile(_ code: String, name: String) -> PrimaryRecallProfile {
        return PrimaryRecallProfile(
            code: code,
            name: name,
            visitMinutes: 0,
            copay: 0.0,
            reviewer: "",
            status: PrimaryRecallProfileStatus.idle
        )
    }
}
