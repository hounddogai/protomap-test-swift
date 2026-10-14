import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal metric is in its life cycle.
    enum GoalMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a goal metric and its current status.
    final class GoalMetric {
        var code: String
        var name: String
        var pinned: Bool
        var specialty: String
        var retries: Int
        var endsAt: Int
        var ward: String
        var channel: String
        var ownerID: String
        var status: GoalMetricStatus

        init(code: String, name: String, pinned: Bool, specialty: String, retries: Int, endsAt: Int, ward: String, channel: String, ownerID: String, status: GoalMetricStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.specialty = specialty
            self.retries = retries
            self.endsAt = endsAt
            self.ward = ward
            self.channel = channel
            self.ownerID = ownerID
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

        func canMoveTo(_ next: GoalMetricStatus) -> Bool {
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
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == GoalMetricStatus.failed
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

        func moveTo(_ next: GoalMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return (Double(retries) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> GoalMetric {
            return GoalMetric(
                code: code,
                name: name,
                pinned: pinned,
                specialty: specialty,
                retries: retries,
                endsAt: endsAt,
                ward: ward,
                channel: channel,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a goal metric in status new.
    static func newGoalMetric(_ code: String, name: String) -> GoalMetric {
        return GoalMetric(
            code: code,
            name: name,
            pinned: false,
            specialty: "",
            retries: 0,
            endsAt: 0,
            ward: "",
            channel: "",
            ownerID: "",
            status: GoalMetricStatus.new
        )
    }
}
