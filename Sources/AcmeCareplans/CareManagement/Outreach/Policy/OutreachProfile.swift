import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach profile is in its life cycle.
    enum OutreachProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a outreach profile and its current status.
    final class OutreachProfile {
        var code: String
        var title: String
        var endsAt: Int
        var budget: Double
        var dosageMg: Double
        var status: OutreachProfileStatus

        init(code: String, title: String, endsAt: Int, budget: Double, dosageMg: Double, status: OutreachProfileStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.budget = budget
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: OutreachProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == OutreachProfileStatus.running
            case .queued:
                return next == OutreachProfileStatus.done
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

        func moveTo(_ next: OutreachProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((dosageMg + budget) * 100).rounded() / 100
        }

        func copyValue() -> OutreachProfile {
            return OutreachProfile(
                code: code,
                title: title,
                endsAt: endsAt,
                budget: budget,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach profile in status new.
    static func newOutreachProfile(_ code: String, title: String) -> OutreachProfile {
        return OutreachProfile(
            code: code,
            title: title,
            endsAt: 0,
            budget: 0.0,
            dosageMg: 0.0,
            status: OutreachProfileStatus.new
        )
    }
}
