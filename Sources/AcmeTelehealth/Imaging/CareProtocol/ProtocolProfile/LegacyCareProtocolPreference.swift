import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy care protocol preference is in its life cycle.
    enum LegacyCareProtocolPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy care protocol preference. Its code is unique within a tenant.
    final class LegacyCareProtocolPreference {
        var code: String
        var title: String
        var externalRef: String
        var phone: String
        var currency: String
        var version: Int
        var copay: Double
        var category: String
        var batchSize: Int
        var visitMinutes: Int
        var status: LegacyCareProtocolPreferenceStatus

        init(code: String, title: String, externalRef: String, phone: String, currency: String, version: Int, copay: Double, category: String, batchSize: Int, visitMinutes: Int, status: LegacyCareProtocolPreferenceStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.phone = phone
            self.currency = currency
            self.version = version
            self.copay = copay
            self.category = category
            self.batchSize = batchSize
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCareProtocolPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LegacyCareProtocolPreferenceStatus.completed || next == LegacyCareProtocolPreferenceStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LegacyCareProtocolPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care protocol preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return (Double(batchSize) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCareProtocolPreference {
            return LegacyCareProtocolPreference(
                code: code,
                title: title,
                externalRef: externalRef,
                phone: phone,
                currency: currency,
                version: version,
                copay: copay,
                category: category,
                batchSize: batchSize,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy care protocol preference in status planned.
    static func newLegacyCareProtocolPreference(_ code: String, title: String) -> LegacyCareProtocolPreference {
        return LegacyCareProtocolPreference(
            code: code,
            title: title,
            externalRef: "",
            phone: "",
            currency: "",
            version: 0,
            copay: 0.0,
            category: "",
            batchSize: 0,
            visitMinutes: 0,
            status: LegacyCareProtocolPreferenceStatus.planned
        )
    }
}
