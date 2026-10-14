import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional panel digest is in its life cycle.
    enum RegionalPanelDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional panel digest as the panel team keeps it.
    final class RegionalPanelDigest {
        var code: String
        var title: String
        var tags: [String]
        var clinicianID: String
        var checksum: String
        var refills: Int
        var unit: String
        var floorValue: Double
        var status: RegionalPanelDigestStatus

        init(code: String, title: String, tags: [String], clinicianID: String, checksum: String, refills: Int, unit: String, floorValue: Double, status: RegionalPanelDigestStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.refills = refills
            self.unit = unit
            self.floorValue = floorValue
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

        func canMoveTo(_ next: RegionalPanelDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalPanelDigestStatus.scheduled || next == RegionalPanelDigestStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RegionalPanelDigestStatus.completed
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

        func moveTo(_ next: RegionalPanelDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional panel digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional panel digest") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return (floorValue * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> RegionalPanelDigest {
            return RegionalPanelDigest(
                code: code,
                title: title,
                tags: tags,
                clinicianID: clinicianID,
                checksum: checksum,
                refills: refills,
                unit: unit,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional panel digest in status planned.
    static func newRegionalPanelDigest(_ code: String, title: String) -> RegionalPanelDigest {
        return RegionalPanelDigest(
            code: code,
            title: title,
            tags: [],
            clinicianID: "",
            checksum: "",
            refills: 0,
            unit: "",
            floorValue: 0.0,
            status: RegionalPanelDigestStatus.planned
        )
    }
}
