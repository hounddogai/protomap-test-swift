import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted priority tier is in its life cycle.
    enum WeightedPriorityTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a weighted priority tier and its current status.
    final class WeightedPriorityTier {
        var code: String
        var label: String
        var externalRef: String
        var ownerID: String
        var approved: Bool
        var phone: String
        var priority: Int
        var minimum: Double
        var status: WeightedPriorityTierStatus

        init(code: String, label: String, externalRef: String, ownerID: String, approved: Bool, phone: String, priority: Int, minimum: Double, status: WeightedPriorityTierStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.approved = approved
            self.phone = phone
            self.priority = priority
            self.minimum = minimum
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

        func canMoveTo(_ next: WeightedPriorityTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
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
                return next == WeightedPriorityTierStatus.done
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

        func moveTo(_ next: WeightedPriorityTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted priority tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return (Double(priority) * minimum * 100).rounded() / 100
        }

        func copyValue() -> WeightedPriorityTier {
            return WeightedPriorityTier(
                code: code,
                label: label,
                externalRef: externalRef,
                ownerID: ownerID,
                approved: approved,
                phone: phone,
                priority: priority,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted priority tier in status new.
    static func newWeightedPriorityTier(_ code: String, label: String) -> WeightedPriorityTier {
        return WeightedPriorityTier(
            code: code,
            label: label,
            externalRef: "",
            ownerID: "",
            approved: false,
            phone: "",
            priority: 0,
            minimum: 0.0,
            status: WeightedPriorityTierStatus.new
        )
    }
}
