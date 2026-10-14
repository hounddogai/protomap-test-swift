import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary snapshot is in its life cycle.
    enum FormularySnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A formulary snapshot. Its code is unique within a tenant.
    final class FormularySnapshot {
        var code: String
        var title: String
        var maximum: Double
        var ratio: Double
        var approved: Bool
        var discount: Double
        var status: FormularySnapshotStatus

        init(code: String, title: String, maximum: Double, ratio: Double, approved: Bool, discount: Double, status: FormularySnapshotStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.ratio = ratio
            self.approved = approved
            self.discount = discount
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

        func canMoveTo(_ next: FormularySnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == FormularySnapshotStatus.published || next == FormularySnapshotStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FormularySnapshotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("formulary snapshot") \(code)"
        }

        func weightedExposure() -> Double {
            return ((ratio + maximum) * 100).rounded() / 100
        }

        func copyValue() -> FormularySnapshot {
            return FormularySnapshot(
                code: code,
                title: title,
                maximum: maximum,
                ratio: ratio,
                approved: approved,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a formulary snapshot in status created.
    static func newFormularySnapshot(_ code: String, title: String) -> FormularySnapshot {
        return FormularySnapshot(
            code: code,
            title: title,
            maximum: 0.0,
            ratio: 0.0,
            approved: false,
            discount: 0.0,
            status: FormularySnapshotStatus.created
        )
    }
}
