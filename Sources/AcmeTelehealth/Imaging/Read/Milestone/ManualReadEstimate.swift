import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual read estimate is in its life cycle.
    enum ManualReadEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual read estimate. Its code is unique within a tenant.
    final class ManualReadEstimate {
        var code: String
        var title: String
        var phone: String
        var graceDays: Int
        var currency: String
        var status: ManualReadEstimateStatus

        init(code: String, title: String, phone: String, graceDays: Int, currency: String, status: ManualReadEstimateStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.graceDays = graceDays
            self.currency = currency
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

        func canMoveTo(_ next: ManualReadEstimateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ManualReadEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual read estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> ManualReadEstimate {
            return ManualReadEstimate(
                code: code,
                title: title,
                phone: phone,
                graceDays: graceDays,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual read estimate in status created.
    static func newManualReadEstimate(_ code: String, title: String) -> ManualReadEstimate {
        return ManualReadEstimate(
            code: code,
            title: title,
            phone: "",
            graceDays: 0,
            currency: "",
            status: ManualReadEstimateStatus.created
        )
    }
}
