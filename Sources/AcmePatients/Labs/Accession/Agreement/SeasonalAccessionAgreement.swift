import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal accession agreement is in its life cycle.
    enum SeasonalAccessionAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal accession agreement and its current status.
    final class SeasonalAccessionAgreement {
        var code: String
        var title: String
        var graceDays: Int
        var encounterID: String
        var ceiling: Double
        var status: SeasonalAccessionAgreementStatus

        init(code: String, title: String, graceDays: Int, encounterID: String, ceiling: Double, status: SeasonalAccessionAgreementStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.encounterID = encounterID
            self.ceiling = ceiling
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

        func canMoveTo(_ next: SeasonalAccessionAgreementStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalAccessionAgreementStatus.running || next == SeasonalAccessionAgreementStatus.done
            case .running:
                return next == SeasonalAccessionAgreementStatus.done || next == SeasonalAccessionAgreementStatus.failed
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

        func moveTo(_ next: SeasonalAccessionAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal accession agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((ceiling + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAccessionAgreement {
            return SeasonalAccessionAgreement(
                code: code,
                title: title,
                graceDays: graceDays,
                encounterID: encounterID,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal accession agreement in status new.
    static func newSeasonalAccessionAgreement(_ code: String, title: String) -> SeasonalAccessionAgreement {
        return SeasonalAccessionAgreement(
            code: code,
            title: title,
            graceDays: 0,
            encounterID: "",
            ceiling: 0.0,
            status: SeasonalAccessionAgreementStatus.new
        )
    }
}
