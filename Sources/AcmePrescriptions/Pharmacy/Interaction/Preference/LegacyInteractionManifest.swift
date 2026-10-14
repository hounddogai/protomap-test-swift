import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy interaction manifest is in its life cycle.
    enum LegacyInteractionManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy interaction manifest as the interaction team keeps it.
    final class LegacyInteractionManifest {
        var code: String
        var label: String
        var locale: String
        var weight: Double
        var startsAt: Int
        var batchSize: Int
        var region: String
        var status: LegacyInteractionManifestStatus

        init(code: String, label: String, locale: String, weight: Double, startsAt: Int, batchSize: Int, region: String, status: LegacyInteractionManifestStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.weight = weight
            self.startsAt = startsAt
            self.batchSize = batchSize
            self.region = region
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

        func canMoveTo(_ next: LegacyInteractionManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LegacyInteractionManifestStatus.rejected
            case .rejected:
                return next == LegacyInteractionManifestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyInteractionManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy interaction manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((weight - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyInteractionManifest {
            return LegacyInteractionManifest(
                code: code,
                label: label,
                locale: locale,
                weight: weight,
                startsAt: startsAt,
                batchSize: batchSize,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy interaction manifest in status proposed.
    static func newLegacyInteractionManifest(_ code: String, label: String) -> LegacyInteractionManifest {
        return LegacyInteractionManifest(
            code: code,
            label: label,
            locale: "",
            weight: 0.0,
            startsAt: 0,
            batchSize: 0,
            region: "",
            status: LegacyInteractionManifestStatus.proposed
        )
    }
}
