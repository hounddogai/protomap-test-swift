import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement rollup is in its life cycle.
    enum StatementRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One statement rollup, with what the planners need to act on it.
    final class StatementRollup {
        var code: String
        var title: String
        var checksum: String
        var diagnosisCode: String
        var minimum: Double
        var refills: Int
        var payer: String
        var unit: String
        var priority: Int
        var encounterID: String
        var rate: Double
        var status: StatementRollupStatus

        init(code: String, title: String, checksum: String, diagnosisCode: String, minimum: Double, refills: Int, payer: String, unit: String, priority: Int, encounterID: String, rate: Double, status: StatementRollupStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.diagnosisCode = diagnosisCode
            self.minimum = minimum
            self.refills = refills
            self.payer = payer
            self.unit = unit
            self.priority = priority
            self.encounterID = encounterID
            self.rate = rate
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

        func canMoveTo(_ next: StatementRollupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
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

        func moveTo(_ next: StatementRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return ((minimum + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> StatementRollup {
            return StatementRollup(
                code: code,
                title: title,
                checksum: checksum,
                diagnosisCode: diagnosisCode,
                minimum: minimum,
                refills: refills,
                payer: payer,
                unit: unit,
                priority: priority,
                encounterID: encounterID,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a statement rollup in status planned.
    static func newStatementRollup(_ code: String, title: String) -> StatementRollup {
        return StatementRollup(
            code: code,
            title: title,
            checksum: "",
            diagnosisCode: "",
            minimum: 0.0,
            refills: 0,
            payer: "",
            unit: "",
            priority: 0,
            encounterID: "",
            rate: 0.0,
            status: StatementRollupStatus.planned
        )
    }
}
