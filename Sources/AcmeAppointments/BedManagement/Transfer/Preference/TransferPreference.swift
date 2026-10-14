import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer preference is in its life cycle.
    enum TransferPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a transfer preference and its current status.
    final class TransferPreference {
        var code: String
        var title: String
        var unit: String
        var facility: String
        var ownerID: String
        var bed: String
        var margin: Double
        var diagnosisCode: String
        var category: String
        var status: TransferPreferenceStatus

        init(code: String, title: String, unit: String, facility: String, ownerID: String, bed: String, margin: Double, diagnosisCode: String, category: String, status: TransferPreferenceStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.facility = facility
            self.ownerID = ownerID
            self.bed = bed
            self.margin = margin
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TransferPreferenceStatus.inReview
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TransferPreferenceStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: TransferPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> TransferPreference {
            return TransferPreference(
                code: code,
                title: title,
                unit: unit,
                facility: facility,
                ownerID: ownerID,
                bed: bed,
                margin: margin,
                diagnosisCode: diagnosisCode,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a transfer preference in status open.
    static func newTransferPreference(_ code: String, title: String) -> TransferPreference {
        return TransferPreference(
            code: code,
            title: title,
            unit: "",
            facility: "",
            ownerID: "",
            bed: "",
            margin: 0.0,
            diagnosisCode: "",
            category: "",
            status: TransferPreferenceStatus.`open`
        )
    }
}
