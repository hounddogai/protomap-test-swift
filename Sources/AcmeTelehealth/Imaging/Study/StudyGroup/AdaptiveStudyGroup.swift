import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive study group is in its life cycle.
    enum AdaptiveStudyGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive study group. Its code is unique within a tenant.
    final class AdaptiveStudyGroup {
        var code: String
        var title: String
        var allergy: String
        var segment: String
        var channel: String
        var quantity: Int
        var status: AdaptiveStudyGroupStatus

        init(code: String, title: String, allergy: String, segment: String, channel: String, quantity: Int, status: AdaptiveStudyGroupStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.segment = segment
            self.channel = channel
            self.quantity = quantity
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

        func canMoveTo(_ next: AdaptiveStudyGroupStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveStudyGroupStatus.validated || next == AdaptiveStudyGroupStatus.retired
            case .validated:
                return next == AdaptiveStudyGroupStatus.published
            case .published:
                return next == AdaptiveStudyGroupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveStudyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive study group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive study group") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> AdaptiveStudyGroup {
            return AdaptiveStudyGroup(
                code: code,
                title: title,
                allergy: allergy,
                segment: segment,
                channel: channel,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive study group in status created.
    static func newAdaptiveStudyGroup(_ code: String, title: String) -> AdaptiveStudyGroup {
        return AdaptiveStudyGroup(
            code: code,
            title: title,
            allergy: "",
            segment: "",
            channel: "",
            quantity: 0,
            status: AdaptiveStudyGroupStatus.created
        )
    }
}
