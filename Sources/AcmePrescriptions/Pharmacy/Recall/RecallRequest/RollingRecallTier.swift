import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling recall tier is in its life cycle.
    enum RollingRecallTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling recall tier as the recall team keeps it.
    final class RollingRecallTier {
        var code: String
        var name: String
        var ratio: Double
        var procedureCode: String
        var notes: String
        var ownerID: String
        var encounterID: String
        var source: String
        var visible: Bool
        var diagnosisCode: String
        var status: RollingRecallTierStatus

        init(code: String, name: String, ratio: Double, procedureCode: String, notes: String, ownerID: String, encounterID: String, source: String, visible: Bool, diagnosisCode: String, status: RollingRecallTierStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.notes = notes
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.source = source
            self.visible = visible
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingRecallTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RollingRecallTierStatus.running || next == RollingRecallTierStatus.failed
            case .running:
                return next == RollingRecallTierStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingRecallTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling recall tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> RollingRecallTier {
            return RollingRecallTier(
                code: code,
                name: name,
                ratio: ratio,
                procedureCode: procedureCode,
                notes: notes,
                ownerID: ownerID,
                encounterID: encounterID,
                source: source,
                visible: visible,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling recall tier in status new.
    static func newRollingRecallTier(_ code: String, name: String) -> RollingRecallTier {
        return RollingRecallTier(
            code: code,
            name: name,
            ratio: 0.0,
            procedureCode: "",
            notes: "",
            ownerID: "",
            encounterID: "",
            source: "",
            visible: false,
            diagnosisCode: "",
            status: RollingRecallTierStatus.new
        )
    }
}
