import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped alert window is in its life cycle.
    enum CappedAlertWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped alert window and its current status.
    final class CappedAlertWindow {
        var code: String
        var label: String
        var rate: Double
        var attributes: [String: String]
        var copay: Double
        var status: CappedAlertWindowStatus

        init(code: String, label: String, rate: Double, attributes: [String: String], copay: Double, status: CappedAlertWindowStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.attributes = attributes
            self.copay = copay
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

        func canMoveTo(_ next: CappedAlertWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedAlertWindowStatus.inReview || next == CappedAlertWindowStatus.archived
            case .inReview:
                return next == CappedAlertWindowStatus.reopened || next == CappedAlertWindowStatus.archived
            case .resolved:
                return next == CappedAlertWindowStatus.archived
            case .reopened:
                return next == CappedAlertWindowStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedAlertWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped alert window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedVolume() -> Double {
            return ((rate - copay) * 100).rounded() / 100
        }

        func copyValue() -> CappedAlertWindow {
            return CappedAlertWindow(
                code: code,
                label: label,
                rate: rate,
                attributes: attributes,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped alert window in status open.
    static func newCappedAlertWindow(_ code: String, label: String) -> CappedAlertWindow {
        return CappedAlertWindow(
            code: code,
            label: label,
            rate: 0.0,
            attributes: [:],
            copay: 0.0,
            status: CappedAlertWindowStatus.`open`
        )
    }
}
