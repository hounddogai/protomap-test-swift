import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census manifest is in its life cycle.
    enum CensusManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A census manifest. Its code is unique within a tenant.
    final class CensusManifest {
        var code: String
        var name: String
        var archived: Bool
        var country: String
        var ceiling: Double
        var notes: String
        var currency: String
        var source: String
        var externalRef: String
        var status: CensusManifestStatus

        init(code: String, name: String, archived: Bool, country: String, ceiling: Double, notes: String, currency: String, source: String, externalRef: String, status: CensusManifestStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.country = country
            self.ceiling = ceiling
            self.notes = notes
            self.currency = currency
            self.source = source
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusManifestStatus) -> Bool {
            switch status {
            case .planned:
                return next == CensusManifestStatus.completed || next == CensusManifestStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CensusManifestStatus.cancelled
            case .completed:
                return next == CensusManifestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("census manifest") \(code)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> CensusManifest {
            return CensusManifest(
                code: code,
                name: name,
                archived: archived,
                country: country,
                ceiling: ceiling,
                notes: notes,
                currency: currency,
                source: source,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a census manifest in status planned.
    static func newCensusManifest(_ code: String, name: String) -> CensusManifest {
        return CensusManifest(
            code: code,
            name: name,
            archived: false,
            country: "",
            ceiling: 0.0,
            notes: "",
            currency: "",
            source: "",
            externalRef: "",
            status: CensusManifestStatus.planned
        )
    }
}
