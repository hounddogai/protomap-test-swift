import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network notice is in its life cycle.
    enum ManualNetworkNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual network notice as the network team keeps it.
    final class ManualNetworkNotice {
        var code: String
        var name: String
        var discount: Double
        var bed: String
        var ratio: Double
        var segment: String
        var dosageMg: Double
        var rate: Double
        var weight: Double
        var active: Bool
        var approved: Bool
        var status: ManualNetworkNoticeStatus

        init(code: String, name: String, discount: Double, bed: String, ratio: Double, segment: String, dosageMg: Double, rate: Double, weight: Double, active: Bool, approved: Bool, status: ManualNetworkNoticeStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.bed = bed
            self.ratio = ratio
            self.segment = segment
            self.dosageMg = dosageMg
            self.rate = rate
            self.weight = weight
            self.active = active
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualNetworkNoticeStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ManualNetworkNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual network notice") \(code)"
        }

        func netExposure() -> Double {
            return ((rate - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkNotice {
            return ManualNetworkNotice(
                code: code,
                name: name,
                discount: discount,
                bed: bed,
                ratio: ratio,
                segment: segment,
                dosageMg: dosageMg,
                rate: rate,
                weight: weight,
                active: active,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual network notice in status draft.
    static func newManualNetworkNotice(_ code: String, name: String) -> ManualNetworkNotice {
        return ManualNetworkNotice(
            code: code,
            name: name,
            discount: 0.0,
            bed: "",
            ratio: 0.0,
            segment: "",
            dosageMg: 0.0,
            rate: 0.0,
            weight: 0.0,
            active: false,
            approved: false,
            status: ManualNetworkNoticeStatus.draft
        )
    }
}
