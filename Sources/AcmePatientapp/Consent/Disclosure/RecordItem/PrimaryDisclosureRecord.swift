import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary disclosure record is in its life cycle.
    enum PrimaryDisclosureRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a primary disclosure record and its current status.
    final class PrimaryDisclosureRecord {
        var code: String
        var name: String
        var version: Int
        var diagnosisCode: String
        var copay: Double
        var status: PrimaryDisclosureRecordStatus

        init(code: String, name: String, version: Int, diagnosisCode: String, copay: Double, status: PrimaryDisclosureRecordStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.diagnosisCode = diagnosisCode
            self.copay = copay
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

        func canMoveTo(_ next: PrimaryDisclosureRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimaryDisclosureRecordStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PrimaryDisclosureRecordStatus.cancelled
            case .completed:
                return next == PrimaryDisclosureRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryDisclosureRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary disclosure record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("primary disclosure record") \(code)"
        }

        func projectedVolume() -> Double {
            return ((copay - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDisclosureRecord {
            return PrimaryDisclosureRecord(
                code: code,
                name: name,
                version: version,
                diagnosisCode: diagnosisCode,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary disclosure record in status planned.
    static func newPrimaryDisclosureRecord(_ code: String, name: String) -> PrimaryDisclosureRecord {
        return PrimaryDisclosureRecord(
            code: code,
            name: name,
            version: 0,
            diagnosisCode: "",
            copay: 0.0,
            status: PrimaryDisclosureRecordStatus.planned
        )
    }
}
