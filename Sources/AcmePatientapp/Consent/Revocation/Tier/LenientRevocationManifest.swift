import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient revocation manifest is in its life cycle.
    enum LenientRevocationManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient revocation manifest as the revocation team keeps it.
    final class LenientRevocationManifest {
        var code: String
        var label: String
        var batchSize: Int
        var region: String
        var dosageMg: Double
        var floorValue: Double
        var windowDays: Int
        var bed: String
        var score: Double
        var description: String
        var status: LenientRevocationManifestStatus

        init(code: String, label: String, batchSize: Int, region: String, dosageMg: Double, floorValue: Double, windowDays: Int, bed: String, score: Double, description: String, status: LenientRevocationManifestStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.region = region
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.windowDays = windowDays
            self.bed = bed
            self.score = score
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientRevocationManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientRevocationManifestStatus.pending
            case .pending:
                return next == LenientRevocationManifestStatus.suspended || next == LenientRevocationManifestStatus.closed
            case .active:
                return next == LenientRevocationManifestStatus.suspended || next == LenientRevocationManifestStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LenientRevocationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient revocation manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(batchSize) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LenientRevocationManifest {
            return LenientRevocationManifest(
                code: code,
                label: label,
                batchSize: batchSize,
                region: region,
                dosageMg: dosageMg,
                floorValue: floorValue,
                windowDays: windowDays,
                bed: bed,
                score: score,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient revocation manifest in status draft.
    static func newLenientRevocationManifest(_ code: String, label: String) -> LenientRevocationManifest {
        return LenientRevocationManifest(
            code: code,
            label: label,
            batchSize: 0,
            region: "",
            dosageMg: 0.0,
            floorValue: 0.0,
            windowDays: 0,
            bed: "",
            score: 0.0,
            description: "",
            status: LenientRevocationManifestStatus.draft
        )
    }
}
