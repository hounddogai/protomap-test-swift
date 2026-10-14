import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered consent form request is in its life cycle.
    enum TieredConsentFormRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered consent form request. Its code is unique within a tenant.
    final class TieredConsentFormRequest {
        var code: String
        var label: String
        var windowDays: Int
        var batchSize: Int
        var region: String
        var locale: String
        var graceDays: Int
        var visitMinutes: Int
        var category: String
        var active: Bool
        var status: TieredConsentFormRequestStatus

        init(code: String, label: String, windowDays: Int, batchSize: Int, region: String, locale: String, graceDays: Int, visitMinutes: Int, category: String, active: Bool, status: TieredConsentFormRequestStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.region = region
            self.locale = locale
            self.graceDays = graceDays
            self.visitMinutes = visitMinutes
            self.category = category
            self.active = active
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

        func canMoveTo(_ next: TieredConsentFormRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TieredConsentFormRequestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredConsentFormRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered consent form request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveVolume() -> Double {
            return ((Double(visitMinutes) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredConsentFormRequest {
            return TieredConsentFormRequest(
                code: code,
                label: label,
                windowDays: windowDays,
                batchSize: batchSize,
                region: region,
                locale: locale,
                graceDays: graceDays,
                visitMinutes: visitMinutes,
                category: category,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered consent form request in status new.
    static func newTieredConsentFormRequest(_ code: String, label: String) -> TieredConsentFormRequest {
        return TieredConsentFormRequest(
            code: code,
            label: label,
            windowDays: 0,
            batchSize: 0,
            region: "",
            locale: "",
            graceDays: 0,
            visitMinutes: 0,
            category: "",
            active: false,
            status: TieredConsentFormRequestStatus.new
        )
    }
}
