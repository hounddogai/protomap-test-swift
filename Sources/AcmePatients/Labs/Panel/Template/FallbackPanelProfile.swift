import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback panel profile is in its life cycle.
    enum FallbackPanelProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback panel profile as the panel team keeps it.
    final class FallbackPanelProfile {
        var code: String
        var title: String
        var graceDays: Int
        var discount: Double
        var dosageMg: Double
        var specialty: String
        var revision: Int
        var sequence: Int
        var batchSize: Int
        var label: String
        var status: FallbackPanelProfileStatus

        init(code: String, title: String, graceDays: Int, discount: Double, dosageMg: Double, specialty: String, revision: Int, sequence: Int, batchSize: Int, label: String, status: FallbackPanelProfileStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.discount = discount
            self.dosageMg = dosageMg
            self.specialty = specialty
            self.revision = revision
            self.sequence = sequence
            self.batchSize = batchSize
            self.label = label
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackPanelProfileStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackPanelProfileStatus.inProgress
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: FallbackPanelProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback panel profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("fallback panel profile") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(batchSize) + discount) * 100).rounded() / 100
        }

        func copyValue() -> FallbackPanelProfile {
            return FallbackPanelProfile(
                code: code,
                title: title,
                graceDays: graceDays,
                discount: discount,
                dosageMg: dosageMg,
                specialty: specialty,
                revision: revision,
                sequence: sequence,
                batchSize: batchSize,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback panel profile in status planned.
    static func newFallbackPanelProfile(_ code: String, title: String) -> FallbackPanelProfile {
        return FallbackPanelProfile(
            code: code,
            title: title,
            graceDays: 0,
            discount: 0.0,
            dosageMg: 0.0,
            specialty: "",
            revision: 0,
            sequence: 0,
            batchSize: 0,
            label: "",
            status: FallbackPanelProfileStatus.planned
        )
    }
}
