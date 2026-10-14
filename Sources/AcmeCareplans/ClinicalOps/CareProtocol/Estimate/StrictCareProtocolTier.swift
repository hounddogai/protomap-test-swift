import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict care protocol tier is in its life cycle.
    enum StrictCareProtocolTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One strict care protocol tier, with what the planners need to act on it.
    final class StrictCareProtocolTier {
        var code: String
        var title: String
        var expiresAt: Int
        var batchSize: Int
        var ownerID: String
        var summary: String
        var facility: String
        var externalRef: String
        var retries: Int
        var patientRef: String
        var label: String
        var status: StrictCareProtocolTierStatus

        init(code: String, title: String, expiresAt: Int, batchSize: Int, ownerID: String, summary: String, facility: String, externalRef: String, retries: Int, patientRef: String, label: String, status: StrictCareProtocolTierStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.summary = summary
            self.facility = facility
            self.externalRef = externalRef
            self.retries = retries
            self.patientRef = patientRef
            self.label = label
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

        func canMoveTo(_ next: StrictCareProtocolTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StrictCareProtocolTierStatus.retired
            case .published:
                return next == StrictCareProtocolTierStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictCareProtocolTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict care protocol tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return (Double(expiresAt) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> StrictCareProtocolTier {
            return StrictCareProtocolTier(
                code: code,
                title: title,
                expiresAt: expiresAt,
                batchSize: batchSize,
                ownerID: ownerID,
                summary: summary,
                facility: facility,
                externalRef: externalRef,
                retries: retries,
                patientRef: patientRef,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a strict care protocol tier in status created.
    static func newStrictCareProtocolTier(_ code: String, title: String) -> StrictCareProtocolTier {
        return StrictCareProtocolTier(
            code: code,
            title: title,
            expiresAt: 0,
            batchSize: 0,
            ownerID: "",
            summary: "",
            facility: "",
            externalRef: "",
            retries: 0,
            patientRef: "",
            label: "",
            status: StrictCareProtocolTierStatus.created
        )
    }
}
