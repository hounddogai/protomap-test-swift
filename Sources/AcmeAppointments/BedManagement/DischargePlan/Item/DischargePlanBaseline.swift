import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan baseline is in its life cycle.
    enum DischargePlanBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One discharge plan baseline, with what the planners need to act on it.
    final class DischargePlanBaseline {
        var code: String
        var name: String
        var version: Int
        var limit: Int
        var procedureCode: String
        var visible: Bool
        var currency: String
        var threshold: Double
        var checksum: String
        var phone: String
        var summary: String
        var status: DischargePlanBaselineStatus

        init(code: String, name: String, version: Int, limit: Int, procedureCode: String, visible: Bool, currency: String, threshold: Double, checksum: String, phone: String, summary: String, status: DischargePlanBaselineStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.limit = limit
            self.procedureCode = procedureCode
            self.visible = visible
            self.currency = currency
            self.threshold = threshold
            self.checksum = checksum
            self.phone = phone
            self.summary = summary
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

        func canMoveTo(_ next: DischargePlanBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == DischargePlanBaselineStatus.retired
            case .validated:
                return next == DischargePlanBaselineStatus.published
            case .published:
                return next == DischargePlanBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netExposure() -> Double {
            return ((threshold + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanBaseline {
            return DischargePlanBaseline(
                code: code,
                name: name,
                version: version,
                limit: limit,
                procedureCode: procedureCode,
                visible: visible,
                currency: currency,
                threshold: threshold,
                checksum: checksum,
                phone: phone,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan baseline in status created.
    static func newDischargePlanBaseline(_ code: String, name: String) -> DischargePlanBaseline {
        return DischargePlanBaseline(
            code: code,
            name: name,
            version: 0,
            limit: 0,
            procedureCode: "",
            visible: false,
            currency: "",
            threshold: 0.0,
            checksum: "",
            phone: "",
            summary: "",
            status: DischargePlanBaselineStatus.created
        )
    }
}
