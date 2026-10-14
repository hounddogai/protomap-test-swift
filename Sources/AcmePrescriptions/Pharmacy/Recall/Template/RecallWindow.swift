import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall window is in its life cycle.
    enum RecallWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A recall window. Its code is unique within a tenant.
    final class RecallWindow {
        var code: String
        var title: String
        var reviewer: String
        var discount: Double
        var margin: Double
        var patientRef: String
        var approved: Bool
        var status: RecallWindowStatus

        init(code: String, title: String, reviewer: String, discount: Double, margin: Double, patientRef: String, approved: Bool, status: RecallWindowStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.discount = discount
            self.margin = margin
            self.patientRef = patientRef
            self.approved = approved
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

        func canMoveTo(_ next: RecallWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RecallWindowStatus.running || next == RecallWindowStatus.failed
            case .running:
                return next == RecallWindowStatus.failed
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

        func moveTo(_ next: RecallWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return (discount * margin * 100).rounded() / 100
        }

        func copyValue() -> RecallWindow {
            return RecallWindow(
                code: code,
                title: title,
                reviewer: reviewer,
                discount: discount,
                margin: margin,
                patientRef: patientRef,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a recall window in status new.
    static func newRecallWindow(_ code: String, title: String) -> RecallWindow {
        return RecallWindow(
            code: code,
            title: title,
            reviewer: "",
            discount: 0.0,
            margin: 0.0,
            patientRef: "",
            approved: false,
            status: RecallWindowStatus.new
        )
    }
}
