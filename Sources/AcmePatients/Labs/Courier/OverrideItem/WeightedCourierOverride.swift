import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted courier override is in its life cycle.
    enum WeightedCourierOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a weighted courier override and its current status.
    final class WeightedCourierOverride {
        var code: String
        var label: String
        var limit: Int
        var name: String
        var contactEmail: String
        var status: WeightedCourierOverrideStatus

        init(code: String, label: String, limit: Int, name: String, contactEmail: String, status: WeightedCourierOverrideStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.name = name
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: WeightedCourierOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedCourierOverrideStatus.queued || next == WeightedCourierOverrideStatus.running
            case .queued:
                return next == WeightedCourierOverrideStatus.done
            case .running:
                return next == WeightedCourierOverrideStatus.done || next == WeightedCourierOverrideStatus.failed
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

        func moveTo(_ next: WeightedCourierOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted courier override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> WeightedCourierOverride {
            return WeightedCourierOverride(
                code: code,
                label: label,
                limit: limit,
                name: name,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted courier override in status new.
    static func newWeightedCourierOverride(_ code: String, label: String) -> WeightedCourierOverride {
        return WeightedCourierOverride(
            code: code,
            label: label,
            limit: 0,
            name: "",
            contactEmail: "",
            status: WeightedCourierOverrideStatus.new
        )
    }
}
