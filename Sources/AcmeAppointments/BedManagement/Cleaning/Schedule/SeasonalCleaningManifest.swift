import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal cleaning manifest is in its life cycle.
    enum SeasonalCleaningManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal cleaning manifest. Its code is unique within a tenant.
    final class SeasonalCleaningManifest {
        var code: String
        var name: String
        var checksum: String
        var clinicianID: String
        var weight: Double
        var createdAt: Int
        var status: SeasonalCleaningManifestStatus

        init(code: String, name: String, checksum: String, clinicianID: String, weight: Double, createdAt: Int, status: SeasonalCleaningManifestStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.clinicianID = clinicianID
            self.weight = weight
            self.createdAt = createdAt
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

        func canMoveTo(_ next: SeasonalCleaningManifestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SeasonalCleaningManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal cleaning manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal cleaning manifest") \(code)"
        }

        func netVolume() -> Double {
            return ((weight + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCleaningManifest {
            return SeasonalCleaningManifest(
                code: code,
                name: name,
                checksum: checksum,
                clinicianID: clinicianID,
                weight: weight,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal cleaning manifest in status planned.
    static func newSeasonalCleaningManifest(_ code: String, name: String) -> SeasonalCleaningManifest {
        return SeasonalCleaningManifest(
            code: code,
            name: name,
            checksum: "",
            clinicianID: "",
            weight: 0.0,
            createdAt: 0,
            status: SeasonalCleaningManifestStatus.planned
        )
    }
}
