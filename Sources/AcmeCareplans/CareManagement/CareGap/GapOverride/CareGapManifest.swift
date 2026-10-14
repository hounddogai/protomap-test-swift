import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap manifest is in its life cycle.
    enum CareGapManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One care gap manifest, with what the planners need to act on it.
    final class CareGapManifest {
        var code: String
        var title: String
        var windowDays: Int
        var rate: Double
        var amount: Double
        var phone: String
        var procedureCode: String
        var version: Int
        var refills: Int
        var clinicianID: String
        var status: CareGapManifestStatus

        init(code: String, title: String, windowDays: Int, rate: Double, amount: Double, phone: String, procedureCode: String, version: Int, refills: Int, clinicianID: String, status: CareGapManifestStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.rate = rate
            self.amount = amount
            self.phone = phone
            self.procedureCode = procedureCode
            self.version = version
            self.refills = refills
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapManifestStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareGapManifestStatus.ready || next == CareGapManifestStatus.draining
            case .warming:
                return next == CareGapManifestStatus.ready || next == CareGapManifestStatus.draining
            case .ready:
                return next == CareGapManifestStatus.draining
            case .draining:
                return next == CareGapManifestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((rate + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapManifest {
            return CareGapManifest(
                code: code,
                title: title,
                windowDays: windowDays,
                rate: rate,
                amount: amount,
                phone: phone,
                procedureCode: procedureCode,
                version: version,
                refills: refills,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care gap manifest in status idle.
    static func newCareGapManifest(_ code: String, title: String) -> CareGapManifest {
        return CareGapManifest(
            code: code,
            title: title,
            windowDays: 0,
            rate: 0.0,
            amount: 0.0,
            phone: "",
            procedureCode: "",
            version: 0,
            refills: 0,
            clinicianID: "",
            status: CareGapManifestStatus.idle
        )
    }
}
