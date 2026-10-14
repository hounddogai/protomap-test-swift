import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure quota is in its life cycle.
    enum ClosureQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A closure quota. Its code is unique within a tenant.
    final class ClosureQuota {
        var code: String
        var title: String
        var segment: String
        var active: Bool
        var unit: String
        var cost: Double
        var locale: String
        var maximum: Double
        var discount: Double
        var archived: Bool
        var label: String
        var status: ClosureQuotaStatus

        init(code: String, title: String, segment: String, active: Bool, unit: String, cost: Double, locale: String, maximum: Double, discount: Double, archived: Bool, label: String, status: ClosureQuotaStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.active = active
            self.unit = unit
            self.cost = cost
            self.locale = locale
            self.maximum = maximum
            self.discount = discount
            self.archived = archived
            self.label = label
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

        func canMoveTo(_ next: ClosureQuotaStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
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

        func moveTo(_ next: ClosureQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return ((discount + cost) * 100).rounded() / 100
        }

        func copyValue() -> ClosureQuota {
            return ClosureQuota(
                code: code,
                title: title,
                segment: segment,
                active: active,
                unit: unit,
                cost: cost,
                locale: locale,
                maximum: maximum,
                discount: discount,
                archived: archived,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a closure quota in status new.
    static func newClosureQuota(_ code: String, title: String) -> ClosureQuota {
        return ClosureQuota(
            code: code,
            title: title,
            segment: "",
            active: false,
            unit: "",
            cost: 0.0,
            locale: "",
            maximum: 0.0,
            discount: 0.0,
            archived: false,
            label: "",
            status: ClosureQuotaStatus.new
        )
    }
}
