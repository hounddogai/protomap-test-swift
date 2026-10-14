import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback rounding manifest is in its life cycle.
    enum FallbackRoundingManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a fallback rounding manifest and its current status.
    final class FallbackRoundingManifest {
        var code: String
        var label: String
        var reviewer: String
        var sequence: Int
        var title: String
        var channel: String
        var acuity: Int
        var procedureCode: String
        var ward: String
        var status: FallbackRoundingManifestStatus

        init(code: String, label: String, reviewer: String, sequence: Int, title: String, channel: String, acuity: Int, procedureCode: String, ward: String, status: FallbackRoundingManifestStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.sequence = sequence
            self.title = title
            self.channel = channel
            self.acuity = acuity
            self.procedureCode = procedureCode
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackRoundingManifestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == FallbackRoundingManifestStatus.revoked || next == FallbackRoundingManifestStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FallbackRoundingManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback rounding manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedValue() -> Double {
            return (Double(sequence) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRoundingManifest {
            return FallbackRoundingManifest(
                code: code,
                label: label,
                reviewer: reviewer,
                sequence: sequence,
                title: title,
                channel: channel,
                acuity: acuity,
                procedureCode: procedureCode,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback rounding manifest in status requested.
    static func newFallbackRoundingManifest(_ code: String, label: String) -> FallbackRoundingManifest {
        return FallbackRoundingManifest(
            code: code,
            label: label,
            reviewer: "",
            sequence: 0,
            title: "",
            channel: "",
            acuity: 0,
            procedureCode: "",
            ward: "",
            status: FallbackRoundingManifestStatus.requested
        )
    }
}
