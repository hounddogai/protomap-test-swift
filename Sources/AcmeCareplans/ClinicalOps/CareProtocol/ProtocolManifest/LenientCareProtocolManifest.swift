import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient care protocol manifest is in its life cycle.
    enum LenientCareProtocolManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a lenient care protocol manifest and its current status.
    final class LenientCareProtocolManifest {
        var code: String
        var label: String
        var clinicianID: String
        var visible: Bool
        var margin: Double
        var ceiling: Double
        var rate: Double
        var expiresAt: Int
        var channel: String
        var status: LenientCareProtocolManifestStatus

        init(code: String, label: String, clinicianID: String, visible: Bool, margin: Double, ceiling: Double, rate: Double, expiresAt: Int, channel: String, status: LenientCareProtocolManifestStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.visible = visible
            self.margin = margin
            self.ceiling = ceiling
            self.rate = rate
            self.expiresAt = expiresAt
            self.channel = channel
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

        func canMoveTo(_ next: LenientCareProtocolManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LenientCareProtocolManifestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCareProtocolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care protocol manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return ((ceiling - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientCareProtocolManifest {
            return LenientCareProtocolManifest(
                code: code,
                label: label,
                clinicianID: clinicianID,
                visible: visible,
                margin: margin,
                ceiling: ceiling,
                rate: rate,
                expiresAt: expiresAt,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a lenient care protocol manifest in status proposed.
    static func newLenientCareProtocolManifest(_ code: String, label: String) -> LenientCareProtocolManifest {
        return LenientCareProtocolManifest(
            code: code,
            label: label,
            clinicianID: "",
            visible: false,
            margin: 0.0,
            ceiling: 0.0,
            rate: 0.0,
            expiresAt: 0,
            channel: "",
            status: LenientCareProtocolManifestStatus.proposed
        )
    }
}
