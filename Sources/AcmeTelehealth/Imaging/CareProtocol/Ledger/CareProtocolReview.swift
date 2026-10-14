import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol review is in its life cycle.
    enum CareProtocolReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a care protocol review and its current status.
    final class CareProtocolReview {
        var code: String
        var label: String
        var graceDays: Int
        var visible: Bool
        var phone: String
        var payer: String
        var status: CareProtocolReviewStatus

        init(code: String, label: String, graceDays: Int, visible: Bool, phone: String, payer: String, status: CareProtocolReviewStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.visible = visible
            self.phone = phone
            self.payer = payer
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

        func canMoveTo(_ next: CareProtocolReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolReviewStatus.done
            case .queued:
                return next == CareProtocolReviewStatus.running
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CareProtocolReviewStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> CareProtocolReview {
            return CareProtocolReview(
                code: code,
                label: label,
                graceDays: graceDays,
                visible: visible,
                phone: phone,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol review in status new.
    static func newCareProtocolReview(_ code: String, label: String) -> CareProtocolReview {
        return CareProtocolReview(
            code: code,
            label: label,
            graceDays: 0,
            visible: false,
            phone: "",
            payer: "",
            status: CareProtocolReviewStatus.new
        )
    }
}
