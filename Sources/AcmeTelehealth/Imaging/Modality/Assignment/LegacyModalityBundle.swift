import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy modality bundle is in its life cycle.
    enum LegacyModalityBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a legacy modality bundle and its current status.
    final class LegacyModalityBundle {
        var code: String
        var name: String
        var patientRef: String
        var contactEmail: String
        var active: Bool
        var version: Int
        var limit: Int
        var rate: Double
        var threshold: Double
        var attempts: Int
        var summary: String
        var status: LegacyModalityBundleStatus

        init(code: String, name: String, patientRef: String, contactEmail: String, active: Bool, version: Int, limit: Int, rate: Double, threshold: Double, attempts: Int, summary: String, status: LegacyModalityBundleStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.contactEmail = contactEmail
            self.active = active
            self.version = version
            self.limit = limit
            self.rate = rate
            self.threshold = threshold
            self.attempts = attempts
            self.summary = summary
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

        func canMoveTo(_ next: LegacyModalityBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyModalityBundleStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LegacyModalityBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy modality bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return ((rate + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyModalityBundle {
            return LegacyModalityBundle(
                code: code,
                name: name,
                patientRef: patientRef,
                contactEmail: contactEmail,
                active: active,
                version: version,
                limit: limit,
                rate: rate,
                threshold: threshold,
                attempts: attempts,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy modality bundle in status proposed.
    static func newLegacyModalityBundle(_ code: String, name: String) -> LegacyModalityBundle {
        return LegacyModalityBundle(
            code: code,
            name: name,
            patientRef: "",
            contactEmail: "",
            active: false,
            version: 0,
            limit: 0,
            rate: 0.0,
            threshold: 0.0,
            attempts: 0,
            summary: "",
            status: LegacyModalityBundleStatus.proposed
        )
    }
}
