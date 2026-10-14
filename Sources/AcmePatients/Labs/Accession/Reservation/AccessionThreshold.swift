import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession threshold is in its life cycle.
    enum AccessionThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One accession threshold, with what the planners need to act on it.
    final class AccessionThreshold {
        var code: String
        var label: String
        var refills: Int
        var version: Int
        var country: String
        var status: AccessionThresholdStatus

        init(code: String, label: String, refills: Int, version: Int, country: String, status: AccessionThresholdStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.version = version
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AccessionThresholdStatus.approved || next == AccessionThresholdStatus.rejected
            case .approved:
                return next == AccessionThresholdStatus.rejected
            case .rejected:
                return next == AccessionThresholdStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("accession threshold") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(version) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionThreshold {
            return AccessionThreshold(
                code: code,
                label: label,
                refills: refills,
                version: version,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a accession threshold in status proposed.
    static func newAccessionThreshold(_ code: String, label: String) -> AccessionThreshold {
        return AccessionThreshold(
            code: code,
            label: label,
            refills: 0,
            version: 0,
            country: "",
            status: AccessionThresholdStatus.proposed
        )
    }
}
