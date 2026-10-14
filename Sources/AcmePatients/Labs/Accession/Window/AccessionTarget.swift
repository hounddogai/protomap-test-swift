import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession target is in its life cycle.
    enum AccessionTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a accession target and its current status.
    final class AccessionTarget {
        var code: String
        var name: String
        var diagnosisCode: String
        var ownerID: String
        var batchSize: Int
        var description: String
        var status: AccessionTargetStatus

        init(code: String, name: String, diagnosisCode: String, ownerID: String, batchSize: Int, description: String, status: AccessionTargetStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.description = description
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

        func canMoveTo(_ next: AccessionTargetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AccessionTargetStatus.done || next == AccessionTargetStatus.failed
            case .running:
                return next == AccessionTargetStatus.done || next == AccessionTargetStatus.failed
            case .done:
                return next == AccessionTargetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> AccessionTarget {
            return AccessionTarget(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                ownerID: ownerID,
                batchSize: batchSize,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a accession target in status new.
    static func newAccessionTarget(_ code: String, name: String) -> AccessionTarget {
        return AccessionTarget(
            code: code,
            name: name,
            diagnosisCode: "",
            ownerID: "",
            batchSize: 0,
            description: "",
            status: AccessionTargetStatus.new
        )
    }
}
