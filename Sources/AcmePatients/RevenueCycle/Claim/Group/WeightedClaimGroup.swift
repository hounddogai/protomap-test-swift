import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted claim group is in its life cycle.
    enum WeightedClaimGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted claim group as the claim team keeps it.
    final class WeightedClaimGroup {
        var code: String
        var title: String
        var maximum: Double
        var externalRef: String
        var retries: Int
        var visible: Bool
        var facility: String
        var status: WeightedClaimGroupStatus

        init(code: String, title: String, maximum: Double, externalRef: String, retries: Int, visible: Bool, facility: String, status: WeightedClaimGroupStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.externalRef = externalRef
            self.retries = retries
            self.visible = visible
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedClaimGroupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WeightedClaimGroupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedClaimGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted claim group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted claim group") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(retries) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> WeightedClaimGroup {
            return WeightedClaimGroup(
                code: code,
                title: title,
                maximum: maximum,
                externalRef: externalRef,
                retries: retries,
                visible: visible,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted claim group in status created.
    static func newWeightedClaimGroup(_ code: String, title: String) -> WeightedClaimGroup {
        return WeightedClaimGroup(
            code: code,
            title: title,
            maximum: 0.0,
            externalRef: "",
            retries: 0,
            visible: false,
            facility: "",
            status: WeightedClaimGroupStatus.created
        )
    }
}
