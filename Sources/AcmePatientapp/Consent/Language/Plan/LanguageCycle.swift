import AcmePlatform
import Foundation

extension Consent {
    /// Where a language cycle is in its life cycle.
    enum LanguageCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a language cycle and its current status.
    final class LanguageCycle {
        var code: String
        var label: String
        var locale: String
        var active: Bool
        var revision: Int
        var checksum: String
        var budget: Double
        var patientRef: String
        var status: LanguageCycleStatus

        init(code: String, label: String, locale: String, active: Bool, revision: Int, checksum: String, budget: Double, patientRef: String, status: LanguageCycleStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.active = active
            self.revision = revision
            self.checksum = checksum
            self.budget = budget
            self.patientRef = patientRef
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

        func canMoveTo(_ next: LanguageCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == LanguageCycleStatus.completed || next == LanguageCycleStatus.cancelled
            case .scheduled:
                return next == LanguageCycleStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
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

        func moveTo(_ next: LanguageCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedLoad() -> Double {
            return (budget * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> LanguageCycle {
            return LanguageCycle(
                code: code,
                label: label,
                locale: locale,
                active: active,
                revision: revision,
                checksum: checksum,
                budget: budget,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a language cycle in status planned.
    static func newLanguageCycle(_ code: String, label: String) -> LanguageCycle {
        return LanguageCycle(
            code: code,
            label: label,
            locale: "",
            active: false,
            revision: 0,
            checksum: "",
            budget: 0.0,
            patientRef: "",
            status: LanguageCycleStatus.planned
        )
    }
}
