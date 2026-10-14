import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary estimate is in its life cycle.
    enum FormularyEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a formulary estimate and its current status.
    final class FormularyEstimate {
        var code: String
        var title: String
        var graceDays: Int
        var archived: Bool
        var refills: Int
        var ceiling: Double
        var locale: String
        var encounterID: String
        var startsAt: Int
        var status: FormularyEstimateStatus

        init(code: String, title: String, graceDays: Int, archived: Bool, refills: Int, ceiling: Double, locale: String, encounterID: String, startsAt: Int, status: FormularyEstimateStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.archived = archived
            self.refills = refills
            self.ceiling = ceiling
            self.locale = locale
            self.encounterID = encounterID
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyEstimateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FormularyEstimateStatus.draining || next == FormularyEstimateStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: FormularyEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("formulary estimate") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(graceDays) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> FormularyEstimate {
            return FormularyEstimate(
                code: code,
                title: title,
                graceDays: graceDays,
                archived: archived,
                refills: refills,
                ceiling: ceiling,
                locale: locale,
                encounterID: encounterID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a formulary estimate in status idle.
    static func newFormularyEstimate(_ code: String, title: String) -> FormularyEstimate {
        return FormularyEstimate(
            code: code,
            title: title,
            graceDays: 0,
            archived: false,
            refills: 0,
            ceiling: 0.0,
            locale: "",
            encounterID: "",
            startsAt: 0,
            status: FormularyEstimateStatus.idle
        )
    }
}
