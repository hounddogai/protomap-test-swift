import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form adjustment is in its life cycle.
    enum ConsentFormAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One consent form adjustment, with what the planners need to act on it.
    final class ConsentFormAdjustment {
        var code: String
        var title: String
        var version: Int
        var minimum: Double
        var limit: Int
        var clinicianID: String
        var phone: String
        var status: ConsentFormAdjustmentStatus

        init(code: String, title: String, version: Int, minimum: Double, limit: Int, clinicianID: String, phone: String, status: ConsentFormAdjustmentStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.minimum = minimum
            self.limit = limit
            self.clinicianID = clinicianID
            self.phone = phone
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

        func canMoveTo(_ next: ConsentFormAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == ConsentFormAdjustmentStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ConsentFormAdjustmentStatus.failed
            case .done:
                return next == ConsentFormAdjustmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("consent form adjustment") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(version) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormAdjustment {
            return ConsentFormAdjustment(
                code: code,
                title: title,
                version: version,
                minimum: minimum,
                limit: limit,
                clinicianID: clinicianID,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a consent form adjustment in status new.
    static func newConsentFormAdjustment(_ code: String, title: String) -> ConsentFormAdjustment {
        return ConsentFormAdjustment(
            code: code,
            title: title,
            version: 0,
            minimum: 0.0,
            limit: 0,
            clinicianID: "",
            phone: "",
            status: ConsentFormAdjustmentStatus.new
        )
    }
}
