import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol quota is in its life cycle.
    enum CareProtocolQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care protocol quota. Its code is unique within a tenant.
    final class CareProtocolQuota {
        var code: String
        var label: String
        var source: String
        var visitMinutes: Int
        var floorValue: Double
        var currency: String
        var status: CareProtocolQuotaStatus

        init(code: String, label: String, source: String, visitMinutes: Int, floorValue: Double, currency: String, status: CareProtocolQuotaStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.visitMinutes = visitMinutes
            self.floorValue = floorValue
            self.currency = currency
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

        func canMoveTo(_ next: CareProtocolQuotaStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CareProtocolQuotaStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CareProtocolQuotaStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("care protocol quota") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(visitMinutes) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolQuota {
            return CareProtocolQuota(
                code: code,
                label: label,
                source: source,
                visitMinutes: visitMinutes,
                floorValue: floorValue,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care protocol quota in status draft.
    static func newCareProtocolQuota(_ code: String, label: String) -> CareProtocolQuota {
        return CareProtocolQuota(
            code: code,
            label: label,
            source: "",
            visitMinutes: 0,
            floorValue: 0.0,
            currency: "",
            status: CareProtocolQuotaStatus.draft
        )
    }
}
