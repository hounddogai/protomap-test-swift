import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending witness window is in its life cycle.
    enum PendingWitnessWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a pending witness window and its current status.
    final class PendingWitnessWindow {
        var code: String
        var label: String
        var retries: Int
        var facility: String
        var expiresAt: Int
        var locale: String
        var summary: String
        var status: PendingWitnessWindowStatus

        init(code: String, label: String, retries: Int, facility: String, expiresAt: Int, locale: String, summary: String, status: PendingWitnessWindowStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.facility = facility
            self.expiresAt = expiresAt
            self.locale = locale
            self.summary = summary
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

        func canMoveTo(_ next: PendingWitnessWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingWitnessWindowStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingWitnessWindowStatus.reopened || next == PendingWitnessWindowStatus.archived
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

        func moveTo(_ next: PendingWitnessWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending witness window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedVolume() -> Double {
            return ((Double(expiresAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PendingWitnessWindow {
            return PendingWitnessWindow(
                code: code,
                label: label,
                retries: retries,
                facility: facility,
                expiresAt: expiresAt,
                locale: locale,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending witness window in status open.
    static func newPendingWitnessWindow(_ code: String, label: String) -> PendingWitnessWindow {
        return PendingWitnessWindow(
            code: code,
            label: label,
            retries: 0,
            facility: "",
            expiresAt: 0,
            locale: "",
            summary: "",
            status: PendingWitnessWindowStatus.`open`
        )
    }
}
