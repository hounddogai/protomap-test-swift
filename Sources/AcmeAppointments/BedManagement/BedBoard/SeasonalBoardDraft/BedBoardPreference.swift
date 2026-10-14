import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board preference is in its life cycle.
    enum BedBoardPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a bed board preference and its current status.
    final class BedBoardPreference {
        var code: String
        var title: String
        var graceDays: Int
        var expiresAt: Int
        var patientRef: String
        var batchSize: Int
        var discount: Double
        var name: String
        var status: BedBoardPreferenceStatus

        init(code: String, title: String, graceDays: Int, expiresAt: Int, patientRef: String, batchSize: Int, discount: Double, name: String, status: BedBoardPreferenceStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.discount = discount
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                return next == BedBoardPreferenceStatus.pending
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: BedBoardPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return ((Double(graceDays) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardPreference {
            return BedBoardPreference(
                code: code,
                title: title,
                graceDays: graceDays,
                expiresAt: expiresAt,
                patientRef: patientRef,
                batchSize: batchSize,
                discount: discount,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board preference in status draft.
    static func newBedBoardPreference(_ code: String, title: String) -> BedBoardPreference {
        return BedBoardPreference(
            code: code,
            title: title,
            graceDays: 0,
            expiresAt: 0,
            patientRef: "",
            batchSize: 0,
            discount: 0.0,
            name: "",
            status: BedBoardPreferenceStatus.draft
        )
    }
}
