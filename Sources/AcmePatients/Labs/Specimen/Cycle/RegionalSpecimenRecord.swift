import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional specimen record is in its life cycle.
    enum RegionalSpecimenRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional specimen record, with what the planners need to act on it.
    final class RegionalSpecimenRecord {
        var code: String
        var title: String
        var revision: Int
        var floorValue: Double
        var copay: Double
        var score: Double
        var status: RegionalSpecimenRecordStatus

        init(code: String, title: String, revision: Int, floorValue: Double, copay: Double, score: Double, status: RegionalSpecimenRecordStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.floorValue = floorValue
            self.copay = copay
            self.score = score
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

        func canMoveTo(_ next: RegionalSpecimenRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalSpecimenRecordStatus.approved
            case .approved:
                return next == RegionalSpecimenRecordStatus.withdrawn
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

        func moveTo(_ next: RegionalSpecimenRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional specimen record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("regional specimen record") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((copay - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSpecimenRecord {
            return RegionalSpecimenRecord(
                code: code,
                title: title,
                revision: revision,
                floorValue: floorValue,
                copay: copay,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional specimen record in status proposed.
    static func newRegionalSpecimenRecord(_ code: String, title: String) -> RegionalSpecimenRecord {
        return RegionalSpecimenRecord(
            code: code,
            title: title,
            revision: 0,
            floorValue: 0.0,
            copay: 0.0,
            score: 0.0,
            status: RegionalSpecimenRecordStatus.proposed
        )
    }
}
