import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched panel profile is in its life cycle.
    enum BatchedPanelProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched panel profile as the panel team keeps it.
    final class BatchedPanelProfile {
        var code: String
        var title: String
        var discount: Double
        var copay: Double
        var budget: Double
        var floorValue: Double
        var description: String
        var status: BatchedPanelProfileStatus

        init(code: String, title: String, discount: Double, copay: Double, budget: Double, floorValue: Double, description: String, status: BatchedPanelProfileStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.copay = copay
            self.budget = budget
            self.floorValue = floorValue
            self.description = description
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

        func canMoveTo(_ next: BatchedPanelProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BatchedPanelProfileStatus.draining || next == BatchedPanelProfileStatus.stopped
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedPanelProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched panel profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return ((floorValue - discount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedPanelProfile {
            return BatchedPanelProfile(
                code: code,
                title: title,
                discount: discount,
                copay: copay,
                budget: budget,
                floorValue: floorValue,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched panel profile in status idle.
    static func newBatchedPanelProfile(_ code: String, title: String) -> BatchedPanelProfile {
        return BatchedPanelProfile(
            code: code,
            title: title,
            discount: 0.0,
            copay: 0.0,
            budget: 0.0,
            floorValue: 0.0,
            description: "",
            status: BatchedPanelProfileStatus.idle
        )
    }
}
