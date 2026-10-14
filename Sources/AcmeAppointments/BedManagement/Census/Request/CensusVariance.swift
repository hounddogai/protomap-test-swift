import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census variance is in its life cycle.
    enum CensusVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a census variance and its current status.
    final class CensusVariance {
        var code: String
        var title: String
        var patientRef: String
        var batchSize: Int
        var reviewer: String
        var summary: String
        var unit: String
        var status: CensusVarianceStatus

        init(code: String, title: String, patientRef: String, batchSize: Int, reviewer: String, summary: String, unit: String, status: CensusVarianceStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.reviewer = reviewer
            self.summary = summary
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusVarianceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CensusVarianceStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CensusVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> CensusVariance {
            return CensusVariance(
                code: code,
                title: title,
                patientRef: patientRef,
                batchSize: batchSize,
                reviewer: reviewer,
                summary: summary,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a census variance in status created.
    static func newCensusVariance(_ code: String, title: String) -> CensusVariance {
        return CensusVariance(
            code: code,
            title: title,
            patientRef: "",
            batchSize: 0,
            reviewer: "",
            summary: "",
            unit: "",
            status: CensusVarianceStatus.created
        )
    }
}
